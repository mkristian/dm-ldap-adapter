module DataMapper
  module Types
    class LdapArray < DataMapper::Type
      primitive ::Array
      default []
    end
  end
  Property::TYPES << Types::LdapArray unless Property::TYPES.member? Types::LdapArray 
end
