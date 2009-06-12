require 'slf4r/logger'
require 'ldap/digest'

# dummy implementation which turns the extra ldap configuration noops
module DataMapper
  module Resource
 
    module ClassMethods
 
      include ::Slf4r::Logger

      def ldap_properties(resource = nil, &block)
        if block
          @ldap_properties = block
        elsif resource.instance_of? Hash
          @ldap_properties = resource
          logger.debug { "ldap_properties=#{@ldap_properties.inspect}" }
        elsif resource
          logger.debug { "ldap_properties=#{@ldap_properties.call(resource).inspect}" }
        else
          logger.debug { "ldap_properties=#{@ldap_properties.inspect}" }
        end
      end
      
      def treebase(resource = nil, &block)
        if block
          @treebase = block
        elsif resource.instance_of? String
          @treebase = resource
          logger.debug { "treebase=#{@treebase.inspect}" }
        elsif resource
          logger.debug { "treebase=#{@treebase.call(resource).inspect}" }
        else
          logger.debug { "treebase=#{@treebase}" }
        end
      end
      
      def dn_prefix(resource = nil, &block)
        if block
          @dn_prefix = block
        elsif resource.instance_of? Hash
          @dn_prefix = resource
          logger.debug { "dn_prefix=#{@dn_prefix.inspect}" }
        elsif resource
          logger.debug { "dn_prefix=#{@dn_prefix.call(resource).inspect}" }
        else
          logger.debug { "dn_prefix=#{dn_prefix}" }
        end
      end
      
      def multivalue_field(field = nil)
        logger.debug { "multivalue_field = #{field}" } if field
      end
    end
    
    def authenticate(password)
      raise "NotImplemented"
    end
  end
end
