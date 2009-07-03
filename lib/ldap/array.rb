module DataMapper
  module Types
    class LdapArray < DataMapper::Type
      primitive Array
      default Proc.new { Array.new }

      def self.dump(value, property)
        value || []
      end

      def self.load(value, property)
        value || []
      end

    end
  end
  Property::TYPES << Types::LdapArray unless Property::TYPES.member? Types::LdapArray 
end
