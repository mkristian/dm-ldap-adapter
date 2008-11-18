ldap-adapter
============

usecase
-------

the usecase for that implementation was using an ldap server for user authentication and authorization. the ldap server is configured to have posixAccounts and posixGroups. on the datamapper side these accounts/groups are modeled with many-to-many relationship. further more the model classes should be in such a way that they can be used with another repository as well, i.e. they carry some ldap related configuration but this is only relevant for the ldap-adapter.

low level ldap library
----------------------

the ldap library which does the actual ldap protocol stuff is [ruby-ldap](http://ruby-ldap.sourceforge.net/) and it is hidden behind a facade, so one could replace it with a different library or make it pluggable.

distinguished name (DN) of a model
----------------------------------

there are three parts which makes the DN of a model, the base from the ldap conncetion, the treebase of the model and dn_prefix of an instance.

    class User
      include DataMapper::Resource
      property :id, Serial, :field => "uidnumber"
      dn_prefix { |user| "uid=#{user.login}"}
      treebase "ou=people"
    end

with a base "dc=example,dc=com" we get a DN like the user 'admin'

    uid=admin,ou=people,dc=example,dc=com

ldap entries are be bigger than the model
-----------------------------------------

for example the ldap posixGroup has more attributes than the model class, it needs the 'objectclass' attribute set to 'posixGroup'.

    class Group
      include DataMapper::Resource
      property :id, Serial, :field => "gidnumber"
      property :name,     String, :field => "cn"
      dn_prefix { |group| "cn=#{group.name}" }
      treebase "ou=groups"
      ldap_properties {{ :objectclass => "posixGroup"}}
    end

so with the help of the ldap_properties you can define a block which returns an hash with extra attributes. with block like this you can make some calculations if needed.