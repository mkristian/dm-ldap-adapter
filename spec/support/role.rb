class Role
  include DataMapper::Resource
  property :id,       Serial, :field => "gidNumber"
  property :name,     String, :field => "cn"

  dn_prefix { |role| "cn=#{role.name}" }

  treebase "ou=groups"

  ldap_properties {{:objectclass => "posixGroup"}}

  belongs_to :user
end