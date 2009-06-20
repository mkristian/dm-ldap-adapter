module DataMapper
  module Types
    class LdapArray < DataMapper::Type
      primitive Array
      default Proc.new { Array.new }
    end
  end
  Property::TYPES << Types::LdapArray unless Property::TYPES.member? Types::LdapArray 
end
