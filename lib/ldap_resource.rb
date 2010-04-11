require 'ldap/digest'
require 'dm-core'
require 'ldap/array'

module DataMapper
  module Model
    module LdapResource

      Model.append_inclusions self

      # authenticate the current resource against the stored password
      # @param [String] password to authenticate
      # @return [TrueClass, FalseClass] whether password was right or wrong
      def authenticate(password)
        ldap.authenticate(ldap.dn(self.class.dn_prefix(self),
                                  self.class.treebase),
                          password)
      end

      # if called without parameter or block the given properties get returned.
      # if called with a block then the block gets stored. if called with new
      # properties they get stored. if called with a Resource then either the
      # stored block gets called with that Resource or the stored properties get
      # returned.
      # @param [Hash,DataMapper::Resource] properties_or_resource either a Hash with properties, a Resource or nil
      # @param [block] &block to be stored for later calls when properties_or_resource is nil
      # @return [Hash] when called with a Resource
      def ldap_properties(properties_or_resource = nil, &block)
        if properties_or_resource
          if properties_or_resource.instance_of? Hash
            @ldap_properties = properties_or_resource
          elsif @ldap_properties.instance_of? Hash
            @ldap_properties
          else
            @ldap_properties.call(properties_or_resource)
          end
        else
          @ldap_properties = block
        end
      end

      # if called without parameter or block the given treebase gets returned.
      # if called with a block then the block gets stored. if called with a
      # String then it gets stored. if called with a Resource then either the
      # stored block gets called with that Resource or the stored String gets
      # returned.
      # @param [String,DataMapper::Resource] treebase_or_resource either a String, a Resource or nil
      # @param [block] &block to be stored for later calls when base_or_resource is nil
      # @return [String] when called with a Resource
      def treebase(base_or_resource = nil, &block)
        if base_or_resource
          if base_or_resource.instance_of? String
            @treebase = base_or_resource
          elsif @treebase.instance_of? String
            @treebase
          else
            @treebase.call(base_or_resource)
          end
        else
          if block
            @treebase = block
          else # backwards compatibility
            @treebase
          end
        end
      end

      # if called without parameter or block the given dn_prefix gets returned.
      # if called with a block then the block gets stored. if called with a
      # String then it gets stored. if called with a Resource then either the
      # stored block gets called with that Resource or the stored String gets
      # returned.
      # @param [String,DataMapper::Resource] prefix_or_resource either a String, a Resource or nil
      # @param [&block] block to be stored for later calls
      # @return [String, nil] when called with a Resource
      def dn_prefix(prefix_or_resource = nil, &block)
        if prefix_or_resource
          if prefix_or_resource.instance_of? String
            @ldap_dn = prefix_or_resource
          elsif @ldap_dn.instance_of? String
            @ldap_dn
          else
            @ldap_dn.call(prefix_or_resource)
          end
        else
          @ldap_dn = block
        end
      end

      # if called without parameter then the stored field gets returned
      # otherwise the given parameters gets stored
      # @param [Symbol, String] field a new multivalue_field
      # @return [Symbol] the multivalue_field
      def multivalue_field(field = nil)
        if field.nil?
          @ldap_multivalue_field
        else
          @ldap_multivalue_field = field.to_sym
        end
      end

      private
      # short cut to the ldap facade
      # @return [Ldap::LdapFacade]
      def ldap
        raise "not an ldap adapter #{repository.adapter.name}" unless repository.adapter.respond_to? :ldap
        repository.adapter.ldap
      end
    end

    include LdapResource
  end
end
