require "net/ldap.rb"
module Ldap
  class LdapFacade
    
    # @param config Hash for the ldap connection
    def self.open(config)
      Net::LDAP.open( config ) do |ldap|
        yield ldap
      end
    end
    
    include ::Slf4r::Logger

    # @param config Hash for the ldap connection
    def initialize(config)
      if config.is_a? Hash
        @ldap = Net::LDAP.new( config )
      else
        @ldap = config
      end
    end

    # @param dn_prefix String the prefix of the dn
    # @param treebase the treebase of the dn or any search
    # @param key_field field which carries the integer unique id of the entity
    # @param props Hash of the ldap attributes of the new ldap object
    # @return nil in case of an error or the new id of the created object
    def create_object(dn_prefix, treebase, key_field, props, silence = false)
      base = "#{treebase},#{@ldap.base}"
      id_sym = key_field.downcase.to_sym
      max = 0
      @ldap.search( :base => base, 
                    :attributes => [key_field], 
                    :return_result => false ) do |entry|
        n = entry[id_sym].first.to_i
        max = n if max < n
      end
      id = max + 1
      props[id_sym] = "#{id}"
      if @ldap.add( :dn => dn(dn_prefix, treebase), 
                    :attributes => props) and @ldap.get_operation_result.code.to_s == "0"
        id
      else
        unless silence
          msg = ldap_error("create", 
                             dn(dn_prefix, treebase)) + "\n\t#{props.inspect}"
          # TODO maybe raise always an error
          if @ldap.get_operation_result.code.to_s == "68"
            raise ::DataMapper::PersistenceError.new(msg)
          else
            logger.warn(msg)
          end
        end
        nil
      end
    end

    # @param treebase the treebase of the search
    # @param key_fields Array of fields which carries the integer unique id(s) of the entity
    # @param Array of conditions for the search
    # @return Array of Hashes with a name/values pair for each attribute
    def read_objects(treebase, key_fields, conditions)
      filters = []
      conditions.each do |cond|
        c = cond[2]
        case cond[0]
        when :or_operator
          f = nil
          cond[1].each do |cc|
            ff = case cc[0]
                 when :eql
                   Net::LDAP::Filter.eq( cc[1].to_s, cc[2].to_s )
                 when :gte
                   f = Net::LDAP::Filter.ge( cc[1].to_s, cc[2].to_s )
                 when :lte
                   f = Net::LDAP::Filter.le( cc[1].to_s, cc[2].to_s )
                 when :like
                   f = Net::LDAP::Filter.eq( cc[1].to_s, cc[2].to_s.gsub(/%/, "*").gsub(/_/, "*").gsub(/\*\*/, "*") )
                 else
                   logger.error(cc[0].to_s + " needs coding")
                 end
            if f
              f = f | ff
            else
              f = ff
            end
          end
        when :eql
          if c.nil?
            f = ~ Net::LDAP::Filter.pres( cond[1].to_s )
          elsif c.class == Array
            f = nil
            c.each do |cc|
              if f
                f = f | Net::LDAP::Filter.eq( cond[1].to_s, cc.to_s )
              else
                f = Net::LDAP::Filter.eq( cond[1].to_s, cc.to_s )
              end
            end
            #elsif c.class == Range
            #  p c
            #  f = Net::LDAP::Filter.ge( cond[1].to_s, c.begin.to_s ) & Net::LDAP::Filter.le( cond[1].to_s, c.end.to_s )
          else
            f = Net::LDAP::Filter.eq( cond[1].to_s, c.to_s )
          end
        when :gte
          f = Net::LDAP::Filter.ge( cond[1].to_s, c.to_s )
        when :lte
          f = Net::LDAP::Filter.le( cond[1].to_s, c.to_s )
        when :not
            if c.nil?
              f = Net::LDAP::Filter.pres( cond[1].to_s )
            elsif c.class == Array
              f = nil
              c.each do |cc|
              if f
                f = f | Net::LDAP::Filter.eq( cond[1].to_s, cc.to_s )
              else
                f = Net::LDAP::Filter.eq( cond[1].to_s, cc.to_s )
              end
            end
              f = ~ f
            else
              f = ~ Net::LDAP::Filter.eq( cond[1].to_s, c.to_s )
            end
        when :like
          f = Net::LDAP::Filter.eq( cond[1].to_s, c.to_s.gsub(/%/, "*").gsub(/_/, "*").gsub(/\*\*/, "*") )
        else
          logger.error(cond[0].to_s + " needs coding")
        end
        filters << f if f
      end
      
      filter = nil
      filters.each do |f|
        if filter.nil?
          filter = f
        else
          filter = filter & f
        end
      end
      logger.debug { "search filter: (#{filter.to_s})" }
      result = []
      @ldap.search( :base => "#{treebase},#{@ldap.base}",
                    :filter => filter ) do |res|
        map = to_map(res) 
        #puts map[key_field.to_sym]
        # TODO maybe make filter which removes this unless
        # TODO move this into the ldap_Adapter to make it more general, so that
        # all field with Integer gets converted, etc
        result << map if key_fields.select do |key_field|
          if map.member? key_field.to_sym
            # convert field to integer
            map[key_field.to_sym] = [map[key_field.to_sym].collect { |k| k.to_i != 0 ? k.to_s : k }].flatten
            true
          end
        end.size > 0 # i.e. there was at least one key_field in the map
      end
      result
    end


    # @param dn_prefix String the prefix of the dn
    # @param treebase the treebase of the dn or any search
    # @param actions the add/replace/delete actions on the attributes
    # @return nil in case of an error or true
    def update_object(dn_prefix, treebase, actions)
      if @ldap.modify( :dn => dn(dn_prefix, treebase), 
                       :operations => actions )
        true
      else
        logger.warn(ldap_error("update", 
                               dn(dn_prefix, treebase) + "\n\t#{actions.inspect}"))
        nil
      end
    end

    # @param dn_prefix String the prefix of the dn
    # @param treebase the treebase of the dn or any search
    # @return nil in case of an error or true
    def delete_object(dn_prefix, treebase)
      if @ldap.delete( :dn => dn(dn_prefix, treebase) )
        true
      else
        logger.warn(ldap_error("delete", 
                               dn(dn_prefix, treebase)))
        
        nil
      end
    end

    
    # @param dn String for identifying the ldap object
    # @param password String to be used for authenticate to the dn
    def authenticate(dn, password)
      Net::LDAP.new( { :host => @ldap.host, 
                       :port => @ldap.port, 
                       :auth => { 
                         :method => :simple, 
                         :username => dn, 
                         :password => password 
                       }, 
                       :base => @ldap.base
                     } ).bind
    end

    # helper to concat the dn from the various parts
    # @param dn_prefix String the prefix of the dn
    # @param treebase the treebase of the dn or any search
    # @return the complete dn String
    def dn(dn_prefix, treebase)
      "#{dn_prefix},#{treebase},#{@ldap.base}"
    end

    private
    
    # helper to extract the Hash from the ldap search result
    # @param Entry from the ldap_search
    # @return Hash with name/value pairs of the entry
    def to_map(entry)
      def entry.map
        @myhash
      end
      entry.map
    end
    
    def ldap_error(method, dn)
      "#{method} error: (#{@ldap.get_operation_result.code}) #{@ldap.get_operation_result.message}\n\tDN: #{dn}"
    end
  end
end
