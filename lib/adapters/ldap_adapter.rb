require "dm-core"
require 'slf4r/logger'
# require 'adapters/noop_transaction'

module Ldap

  # the class provides two ways of getting a LdapFacade. either
  # one which is put on the current Thread or a new one
  class LdapConnection

    include ::Slf4r::Logger

    def initialize(options)
      if options[:facade].nil?
        require 'ldap/net_ldap_facade'
        @facade = ::Ldap::NetLdapFacade
      else
        case options[:facade].to_sym
        when :ruby_ldap
          require 'ldap/ruby_ldap_facade'
          @facade = ::Ldap::RubyLdapFacade
        when :net_ldap
          require 'ldap/net_ldap_facade'
          @facade = ::Ldap::NetLdapFacade
        else
          "please add a :facade parameter to the adapter setup. possible values are :ruby_ldap or net_ldap"
        end
      end
      logger.info("using #{@facade}")
      @ldaps = { }
      auth =  {
        :method => :simple,
        :username => options[:bind_name],
        :password => options[:password]
      }
      @config = {
        :host => options[:host],
        :port => options[:port].to_i,
        :auth => auth,
        :base => options[:base]
      }
    end

    # puts a LdapFacade into the current thread and executes the
    # given block.
    def open
      begin
        @facade.open(@config) do |ldap|
          @ldaps[Thread.current] = @facade.new(ldap)
          yield
        end
      ensure
        @ldaps[Thread.current] = nil
      end
    end

    # @return [Ldap::LdapFacade]
    #  either the one from the current Thread or a new one
    def current
      ldap = @ldaps[Thread.current]
      if ldap
        ldap
      else
        @facade.new(@config)
      end
    end
  end
end

require "dm-core"
module DataMapper
  class Query

    class SortCaseInsensitive < Sort
      def initialize(value, ascending = true)
        if(value && value.is_a?(String))
          super(value.upcase, ascending)
        else
          super
        end
      end
    end

    def sort_records_case_insensitive(records)
      sort_order = order.map { |direction| [ direction.target, direction.operator == :asc ] }

      records.sort_by do |record|
        sort_order.map do |(property, ascending)|
          SortCaseInsensitive.new(record_value(record, property), ascending)
        end
      end
    end
  end
  module Adapters
    class LdapAdapter < AbstractAdapter

      # @return [Ldap::LdapFacade]
      #   ready to use LdapFacade
      def ldap
        @ldap_connection.current
      end

      def open_ldap_connection(&block)
        @ldap_connection.open(&block)
      end

      def key_properties(resource)
        resource.model.key.first
      end

      COMPARATORS = { "=" => :eql, ">=" => :gte, "<=" => :lte, "like" => :like }

      # helper to remove datamapper specific classes from the conditions
      # @param [Array] conditions
      #   array of tuples: (action, property, new value)
      # @return [Array]
      #   tuples: (action, attribute name, new value)
      def to_ldap_conditions(query)
        conditions = query.conditions
        ldap_conditions = []
        conditions.operands.each do |c|
          if c.is_a? Array
            props = {}
            query.fields.each{ |f| props[f.name] = f.field}
            or_conditions = []
            c[0].split('or').each do |e|
              e.strip!
              match = e.match("=|<=|>=|like")
              or_conditions << [COMPARATORS[match.values_at(0)[0]],
                                props[match.pre_match.strip.to_sym],
                                match.post_match.strip.gsub(/'/, '')]
            end
            ldap_conditions << [:or_operator, or_conditions, nil]
          else
            comparator = c.slug
            case comparator
            when :raw
            when :not
                # TODO proper recursion !!!
                ldap_conditions << [comparator, c.operands.first.subject.field, c.operands.first.send(:dumped_value)]
            when :in
              ldap_conditions << [:eql, c.subject.field, c.send(:dumped_value)]
            else
              if c.subject.is_a? Ldap::LdapArray
                # assume a single value here !!!
                val = c.send(:dumped_value)
                ldap_conditions << [comparator, c.subject.field, val[1, val.size - 2]]
              else
                ldap_conditions << [comparator, c.subject.field, c.send(:dumped_value)]
              end
            end
          end
        end
        ldap_conditions
      end

      include ::Slf4r::Logger

      # @see AbstractAdapter
#      def transaction_primitive
 #       NoopTransaction.new
  #    end

      public

      def initialize(name, options)
        super(name, options)
        @ldap_connection = ::Ldap::LdapConnection.new(@options)
      end


      def create(resources)
        resources.select do |resource|

          create_resource(resource)

        end.size # just return the number of create resources
      end

      def update(attributes, collection)
        collection.each do |resource|
#puts "update"
#p resource
          update_resource(resource, attributes)

        end.size
      end
      # @param [DataMapper::Resource] resource
      #   to be created
      # @see SimpleAdapter#create_resource
      # @return [Fixnum]
      #    value for the primary key or nil
      def create_resource(resource)
        logger.debug { resource.inspect }

        props = resource.model.ldap_properties(resource)
        key = nil
        resource.send(:properties).each do |prop|
          value = prop.get!(resource)
          if prop.class == ::Ldap::LdapArray
            props[prop.field.to_sym] = value unless value.nil? or value.size == 0
          else
            props[prop.field.to_sym] = value.to_s unless value.nil?
          end
          key = prop if prop.serial?
        end
        resource_dup = resource.dup
        id = ldap.retrieve_next_id(resource.model.treebase,
                                   key_properties(resource).field)
        resource_dup.send("#{key_properties(resource).name}=".to_sym, id)
        props[key_properties(resource).field.to_sym] = "#{id}"
        key_value = begin
                      ldap.create_object(resource.model.dn_prefix(resource_dup),
                                         resource.model.treebase,
                                         key_properties(resource).field,
                                         props, resource.model.multivalue_field)
                    rescue => e
                      raise e unless resource.model.multivalue_field
                      # TODO something with creating these multivalue objects
                    end
        logger.debug { "resource #{resource.inspect} key value: #{key_value.inspect}" + ", multivalue_field: " + resource.model.multivalue_field.to_s }
        if key_value and !key.nil?
          key.set!(resource, key_value.to_i)
          resource
        elsif resource.model.multivalue_field
          multivalue_prop = resource.send(:properties).detect do |prop|
            prop.field.to_sym == resource.model.multivalue_field
          end
          update_resource(resource,
                          { multivalue_prop =>
                            resource.send(multivalue_prop.name.to_sym)})
        else
          nil
        end
      end

      # @param [DataMapper::Resource] resource
      #   to be updated
      # @param [Hash] attributes
      #   new attributes for the resource
      # @see SimpleAdapter#update_resource
      def update_resource(resource, attributes)
        actions = []
        attributes.each do |property, value|
          field = property.field.to_sym #TODO sym needed or string ???
          if property.class == ::Ldap::LdapArray
            value = property.load(value)
            if resource.original_attributes[property].nil?
              value.each do |v|
                actions << [:add, field, v]
              end
            else
              array_actions = []
              resource.original_attributes[property].each do |ov|
                unless value.member? ov
                  actions << [:delete, field, ov.to_s]
                end
              end
              value.each do |v|
                unless resource.original_attributes[property].member? v
                  actions << [:add, field, v.to_s]
                end
              end
              array_actions
            end
          else
            if resource.model.multivalue_field == property.field.to_sym
              if value.nil?
                actions << [:delete, field, resource.attribute_get(property.name).to_s]
              else
                actions << [:add, field, value.to_s]
              end
            elsif value.nil?
              actions << [:delete, field, []]
            elsif resource.original_attributes[property].nil?
              actions << [:add, field, value.to_s]
            else
              actions << [:replace, field, value.to_s]
            end
          end
        end
#puts "actions"
#p actions
#puts
        ldap.update_object(resource.model.dn_prefix(resource),
                           resource.model.treebase,
                           actions)
      end

      # @see AbstractAdapter#delete
      def delete(collection)
        collection.each do |resource|
          if resource.model.multivalue_field
            multivalue_prop = resource.send(:properties).detect do |prop|
              prop.field.to_sym == resource.model.multivalue_field
            end
            update_resource(resource,
                            { multivalue_prop => nil })
          else
            ldap.delete_object(resource.model.dn_prefix(resource),
                               resource.model.treebase)
          end
        end
      end

      # @see AbstractAdapter#read
      def read(query)
        result = []
        resources = read_resources(query)
        resources.each do |resource|
          map = {}
          query.fields.each_with_index do |property, idx|
            map[property.field] = property.typecast(resource[idx])
          end
          result << map
        end

#puts "read_many"
#p result.size
        result = result.uniq if query.unique?
        result = query.match_records(result) if query.model.multivalue_field
        result = query.sort_records_case_insensitive(result)
        result = query.limit_records(result)
        result
      end

      def read_resources(query)
        order_by = query.order.first.target.field
        order_by_sym = order_by.to_sym
        field_names = query.fields.collect {|f| f.field }
        result = ldap.read_objects(query.model.treebase,
                                   query.model.key.collect { |k| k.field },
                                   to_ldap_conditions(query),
                                   field_names, order_by)
#.sort! do |u1, u2|
#          value1 = u1[order_by_sym].first.upcase rescue ""
#          value2 = u2[order_by_sym].first.upcase rescue ""
#          value1 <=> value2
#        end
        if query.model.multivalue_field
          props_result = []
          result.each do |props|
            # run over all values of the multivalue field
            (props[query.model.multivalue_field] || []).each do |value|
              values =  query.fields.collect do |f|
                if query.model.multivalue_field == f.field.to_sym
                  value
                else
                  prop = props[f.field.to_sym].first
                  f.primitive == Integer ? prop.to_i : prop.join
                end
              end
              props_result << values
            end
          end
          props_result
        else # no multivalue field
          result.collect do |props|
            query.fields.collect do |f|
              prop = props[f.field.to_sym]
              if f.class == Ldap::LdapArray
                prop if prop
              elsif prop
                f.primitive == Integer ? prop.first.to_i : prop.join
              end
            end
          end
        end
      end

#      include ::DataMapper::Transaction::Adapter
    end
  end
end
