class TestContact
  include DataMapper::Resource

  property :id,        Serial, :field => "uidNumber"
  property :login,     String, :field => "uid", :unique_index => true
  property :hashed_password,  String, :field => "userPassword", :lazy => true
  property :name,      String, :field => "cn"
  property :mail,      ::Ldap::LdapArray

  dn_prefix { |contact| "uid=#{contact.login}"}

  treebase "ou=people"

  ldap_properties do |contact|
    properties = { :objectclass => ["inetOrgPerson", "posixAccount", "shadowAccount"], :loginshell => "/bin/bash", :gidnumber => "10000" }
    properties[:sn] = "#{contact.name.sub(/.*\ /, "")}"
    properties[:givenname] = "#{contact.name.sub(/\ .*/, "")}"
    properties[:homedirectory] = "/home/#{contact.login}"
    properties
  end

  def password=(password)
    attribute_set(:hashed_password, Ldap::Digest.ssha(password, "--#{Time.now}--#{login}--")) if password
  end
end