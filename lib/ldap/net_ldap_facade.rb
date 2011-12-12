require 'net/ldap'
require 'slf4r'
require 'ldap/conditions_2_filter'

module Ldap
  class NetLdapFacade

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

    def retrieve_next_id(treebase, key_field)
      id_sym = key_field.downcase.to_sym
      max = 0
      @ldap.search( :base => base(treebase),
                    :attributes => [key_field],
                    :return_result => false ) do |entry|
        n = entry[id_sym].first.to_i
        max = n if max < n
      end
      max + 1
    end

    # @param dn_prefix String the prefix of the dn
    # @param treebase the treebase of the dn or any search
    # @param key_field field which carries the integer unique id of the entity
    # @param props Hash of the ldap attributes of the new ldap object
    # @return nil in case of an error or the new id of the created object
    def create_object(dn_prefix, treebase, key_field, props, silence = false)
      if @ldap.add( :dn => dn(dn_prefix, treebase),
                    :attributes => props) || @ldap.get_operation_result.code.to_s == "0"
        props[key_field.to_sym]
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
    def read_objects(treebase, key_fields, conditions, field_names, order_field = nil)
      result = []
      filter = Conditions2Filter.convert(conditions)
      @ldap.search( :base => base(treebase),
                    :attributes => field_names,
                    :filter => filter ) do |res|
        mapp = to_map(field_names, res)

        #puts map[key_field.to_sym]
        # TODO maybe make filter which removes this unless
        # TODO move this into the ldap_Adapter to make it more general, so that
        # all field with Integer gets converted, etc
        result << mapp if key_fields.detect do |key_field|
          mapp.keys.detect {|k| k.to_s.downcase == key_field.downcase }
        end
      end
      result
    end


    # @param dn_prefix String the prefix of the dn
    # @param treebase the treebase of the dn or any search
    # @param actions the add/replace/delete actions on the attributes
    # @return nil in case of an error or true
    def update_object(dn_prefix, treebase, actions)
      if @ldap.modify( :dn => dn(dn_prefix, treebase),
                       :operations => actions ) || @ldap.get_operation_result.code.to_s == "0"
        true
      else
        puts caller.join("\n")
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
      [ dn_prefix, ldap_base(treebase) ].compact.join(",")
    end

    # helper to concat the base from the various parts
    # @param treebase
    # @param ldap_base the ldap_base defaulting to connection ldap_base
    # @return the complete base String
    def base(treebase = nil, ldap_base = @ldap.base)
      [ treebase, ldap_base ].compact.join(",")
    end

    private

    # helper to extract the Hash from the ldap search result
    # @param Entry from the ldap_search
    # @return Hash with name/value pairs of the entry
    def to_map(field_names, entry)
      fields = {:dn => :dn}
      field_names.each { |f| fields[f.downcase.to_sym] = f.to_sym }
      def entry.map
        @myhash
      end
      result = {}
      entry.map.each do |k,v|
        result[fields[k]] = v
      end
      result
    end
    
    def ldap_error(method, dn)
      "#{method} error: (#{@ldap.get_operation_result.code}) #{@ldap.get_operation_result.message}\n\tDN: #{dn}"
    end
  end
end
