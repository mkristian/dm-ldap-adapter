require 'ldap'
require 'slf4r'
require 'ldap/conditions_2_filter'

module Ldap
  class Connection < LDAP::Conn

    attr_reader :base, :host, :port

    def initialize(config)
      super(config[:host], config[:port])
      @base = config[:base]
      @port = config[:port]
      @host = config[:host]
      set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
    end

  end

  class RubyLdapFacade

    # @param config Hash for the ldap connection
    def self.open(config)
      ldap2 = Connection.new(config)
      ldap2.bind(config[:auth][:username], config[:auth][:password]) do |ldap|
        yield ldap
      end
    end

    include ::Slf4r::Logger

    # @param config Hash for the ldap connection
    def initialize(config)
      if config.is_a? Hash
        @ldap2 = Connection.new(config)
        @ldap2.bind(config[:auth][:username], config[:auth][:password])
      else
        @ldap2 = config
      end
    end

    def retrieve_next_id(treebase, key_field)
      max = 0
      @ldap2.search(base(treebase),
                    LDAP::LDAP_SCOPE_SUBTREE,
                    "(objectclass=*)",
                     [key_field]) do |entry|
        n = (entry.vals(key_field) || [0]).first.to_i
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
      mods = props.collect do |k,v|
        LDAP.mod(LDAP::LDAP_MOD_ADD, k.to_s, v.is_a?(::Array) ? v : [v.to_s] )
      end
      if @ldap2.add( dn(dn_prefix, treebase), mods)
        props[key_field.to_sym]
      else
        unless silence
          msg = ldap_error("create",
                             dn(dn_prefix, treebase)) + "\n\t#{props.inspect}"
          # TODO maybe raise always an error
          if @ldap2.get_operation_result.code.to_s == "68"
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
    def read_objects(treebase, key_fields, conditions, field_names, order_field = '')      
      
      if !conditions.nil? and conditions.size > 0
        filter = Conditions2Filter.convert(conditions).to_s
      else
        filter = "(objectclass=*)"
      end

      searchbase = base(treebase)

      # If there is a :dn in the filter skip everything and look it up
      if dn = conditions.detect { |c| c[1] == "dn" } then
        searchbase = dn[2]
        filter = nil
      end

      result = []
      begin
      @ldap2.search(searchbase,
                    LDAP::LDAP_SCOPE_SUBTREE,
                    filter,
                    field_names, false, 0, 0, order_field) do |res|
        mapp = to_map(field_names, res)
        # TODO maybe make filter which removes this unless
        # TODO move this into the ldap_Adapter to make it more general, so that
        # all field with Integer gets converted, etc
        # NOTE: somehow the fields are downcase coming from query.model
        result << mapp if key_fields.detect do |key_field|
            mapp.keys.detect {|k| k.to_s.downcase == key_field.downcase }
          end
        end
      end
      result
    end


    # @param dn_prefix String the prefix of the dn
    # @param treebase the treebase of the dn or any search
    # @param actions the add/replace/delete actions on the attributes
    # @return nil in case of an error or true
    def update_object(dn_prefix, treebase, actions)
      mods = actions.collect do |act|
        mod_op = case act[0]
              when :add
                LDAP::LDAP_MOD_ADD
              when :replace
                LDAP::LDAP_MOD_REPLACE
              when :delete
                LDAP::LDAP_MOD_DELETE
              end
        LDAP.mod(mod_op, act[1].to_s, act[2] == [] ? [] : [act[2].to_s])
      end
      if @ldap2.modify( dn(dn_prefix, treebase),
                       mods )
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
      if @ldap2.delete( dn(dn_prefix, treebase) )
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
      bound = false
      ldap_con = LDAP::Conn.new(@ldap2.host, @ldap2.port)
      ldap_con.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
      begin
        ldap_con.bind(dn, password, LDAP::LDAP_AUTH_SIMPLE) do
          bound = true
        end
      rescue LDAP::ResultError => msg
        if msg.to_s =~ /Invalid\ credentials/i
          logger.info("Invalid Credentials: #{dn}")
        else 
          logger.warn "Authentication Error: #{msg.to_s}"
        end
      end
      bound
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
    def base(treebase = nil, ldap_base = @ldap2.base)
      [ treebase, ldap_base ].compact.join(",")
    end

    private

    # helper to extract the Hash from the ldap search result
    # @param Entry from the ldap_search
    # @return Hash with name/value pairs of the entry
    def to_map(field_names, entry)
      fields = {:dn => :dn}
      field_names.each { |f| fields[f.downcase.to_sym] = f.to_sym }
      map = {}
      LDAP::entry2hash(entry).each do |k,v|
        map[fields[k.downcase.to_sym]] = v
      end
      map
    end

    def ldap_error(method, dn)
      "#{method} error: (#{@ldap2.get_operation_result.code}) #{@ldap2.get_operation_result.message}\n\tDN: #{dn}"
    end
  end
end
