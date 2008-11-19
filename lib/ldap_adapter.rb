module Ldap
  
  # the class provides two ways of getting a LdapFacade. either
  # one which is put on the current Thread or a new one
  class LdapConnection
    
    def initialize(uri)
      @ldaps = { }
      auth =  { 
        :method => :simple,
        :username => uri[:bind_name],
        :password => uri[:password]
      } 
      @config = { 
        :host => uri[:host], 
        :port => uri[:port].to_i, 
        :auth => auth, 
        :base => uri[:base]
      }
    end
    
    # puts a LdapFacade into the current thread and executes the
    # given block.
    def open
      begin
        Ldap::LdapFacade.open(@config) do |ldap|
          @ldaps[Thread.current] = Ldap::LdapFacade.new(ldap)
          yield
        end
      ensure
        @ldaps[Thread.current] = nil 
      end
    end
    
    # @return LdapFacade either the one from the current Thread or a new one
    def current
      ldap = @ldaps[Thread.current]
      if ldap
        ldap
      else
        Ldap::LdapFacade.new(@config)
      end
    end
  end
end

require "dm-core"
module DataMapper
  module Adapters
    class LdapAdapter < SimpleAdapter

      # @return LdapFacade ready to use
      def ldap
        @ldap_connection.current
      end

      def key_properties(resource)
        resource.send(:key_properties).first
      end

      # helper to remove datamapper specific classes from the conditions
      # @param conditions
      # @retrun Array of tuples: [action, attribute name, new value]
      def to_ldap_conditions(conditions)
        ldap_conditions = []
        conditions.each do |c|
          ldap_conditions << [c[0], c[1].field, c[2]]
        end
        ldap_conditions
      end

      public

      # @overwrite from AbstractAdapter
      def initialize(name, uri_or_options)
        super

        @ldap_connection = ::Ldap::LdapConnection.new(@uri)
      end

      # @overwrite from SimpleAdapter
      def create_resource(resource)
        props = resource.class.ldap_properties(resource)
        key = nil
        resource.send(:properties).each do |prop|
          value = prop.get!(resource)
          props[prop.field.to_sym] = value.to_s unless value.nil?
          key = prop if prop.serial?
        end
        key_value = ldap.create_object(resource.model.dn_prefix(resource), 
                                       resource.model.treebase, 
                                       key_properties(resource).field, 
                                       props)
        if key_value
          key.set!(resource, key_value.to_i)
          resource
        elsif resource.model.multivalue_field
          multivalue_prop = resource.send(:properties).detect do |prop|
            prop.field.to_sym == resource.model.multivalue_field
          end
          update_resource(resource, 
                          { multivalue_prop => 
                            resource.send(resource.model.multivalue_field)})
        else
          nil
        end
      end

      # @overwrite from SimpleAdapter
      def update_resource(resource, attributes)
        actions = attributes.collect do |property, value|
          field = property.field.to_sym #TODO sym needed or string ???
          if resource.model.multivalue_field == property.name
            if value.nil?
              [:delete, field, resource.original_values[property.name].to_s]
            else
              [:add, field, value.to_s]
            end
          elsif value.nil?
            [:delete, field, []]
          elsif resource.original_values[property.name].nil?
            [:add, field, value.to_s]            
          else
            [:replace, field, value.to_s]
          end
        end
#puts "actions"
#p actions
#puts
        ldap.update_object(resource.model.dn_prefix(resource), 
                           resource.model.treebase, 
                           actions)
      end

      # @overwrite from SimpleAdapter
      def delete_resource(resource)
        if resource.model.multivalue_field
          # set the original value so update does the right thing
          resource.send("#{resource.model.multivalue_field}=".to_sym, nil)
          update_resource(resource, 
                          { resource.send(:properties)[resource.model.multivalue_field] => nil })
        else
          ldap.delete_object(resource.model.dn_prefix(resource),
                             resource.model.treebase)
        end
      end
      
      # @overwrite from SimpleAdapter
      def read_resource(query)        
        result = ldap.read_objects(query.model.treebase, 
                                   query.model.key.collect { |k| k.field}, 
                                   to_ldap_conditions(query.conditions))
        if query.model.multivalue_field
          resource = result.detect do |item|
            # run over all values of the multivalue field
            item[query.model.multivalue_field].any? do |value|
              values =  query.fields.collect do |f|
                if query.model.multivalue_field == f.field.to_sym 
                  value
                else 
                  item[f.field.to_sym].first 
                end
              end
              resource = query.model.load(values, query)
              return resource if filter_resource(resource, query.conditions)
            end
          end
        else
          values = result.first
          if values
            query.fields.collect do |f|
              values[f.field.to_sym].first
            end
          end
        end
      end
        
      # @overwrite from SimpleAdapter
      def read_resources(query)        
        result = ldap.read_objects(query.model.treebase, 
                                   query.model.key.collect { |k| k.field}, 
                                   to_ldap_conditions(query.conditions))
        if query.model.multivalue_field
          props_result = []
          result.each do |props|
            # run over all values of the multivalue field
            props[query.model.multivalue_field].each do |value|
              values =  query.fields.collect do |f|
                if query.model.multivalue_field == f.field.to_sym 
                  value
                else 
                  props[f.field.to_sym].first 
                end
              end
              resource = query.model.load(values, query)
              props_result << resource if filter_resource(resource, query.conditions)
            end
          end
          props_result
        else # no multivalue field
          result.collect do |props|
            query.fields.collect do |f|
              props[f.field.to_sym].first
            end
          end
        end
      end
    end
  end
end
