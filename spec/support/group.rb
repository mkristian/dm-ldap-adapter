class Group
  include DataMapper::Resource
  property :id,       Serial, :field => "gidNumber"
  property :name,     String, :field => "cn"

  dn_prefix { |group| "cn=#{group.name}" }

  treebase "ou=groups"

  ldap_properties {{:objectclass => "posixGroup"}}
end
