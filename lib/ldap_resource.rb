module DataMapper
  module Resource
    module ClassMethods
      
      # if the resource is nil then the given block 
      # get stored.
      # otherwise the block will be called with resource
      # @param Resource
      # @param &block to be stored for later calls
      def ldap_properties(resource = nil, &block)
        if block
          @ldap_properties = block
        elsif resource
          @ldap_properties.call(resource)
        end
      end
      
      # @param String a new treebase
      # @return String with the treebase
      def treebase(base = nil)
        if base
          @treebase = base
        else
          @treebase
        end
      end
      
      # if the resource is nil then the given block 
      # get stored.
      # otherwise the block will be called with resource
      # @param Resource
      # @param &block to be stored for later calls
      def dn_prefix(resource = nil, &block)
        if block
          @ldap_dn = block
        elsif resource
          @ldap_dn.call(resource)
        end
      end
      
      # @param Symbol or String a new multivalue_field
      # @return Symbol with the multivalue_field
      def multivalue_field(field = nil)
        if field.nil?
          @ldap_multivalue_field
        else
          @ldap_multivalue_field = field.to_sym
        end
      end
    end
    
    # @param String password to authenticate
    # @return true or false whether the password was right or wrong
    def authenticate(password)
      ldap.authenticate(ldap.dn(self.class.dn_prefix(self),
                                self.class.treebase), 
                        password)
    end

    private
    # short cut for the ldap facade
    # @return LdapFacade
    def ldap
      repository.adapter.ldap
    end
  end
end

module Ldap
  module LoggerModule

    def logger
      @logger ||= LoggerFacade.new(self.class)
    end

  end
end
