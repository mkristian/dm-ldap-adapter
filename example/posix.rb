require 'pathname'
require Pathname(__FILE__).dirname.parent.expand_path + 'lib/simple_adapter'
require Pathname(__FILE__).dirname.parent.expand_path + 'lib/ldap_adapter'
require Pathname(__FILE__).dirname.parent.expand_path + 'lib/ldap_resource'
require Pathname(__FILE__).dirname.parent.expand_path + 'lib/ldap_facade'

DataMapper.setup(:default, {
                   :adapter  => 'ldap',
                   :host => 'localhost',
                   :port => '389',
                   :base => ENV['LDAP_BASE'] || "dc=example,dc=com",
                   :bind_name => "cn=admin," + (ENV['LDAP_BASE'] || "dc=example,dc=com"),
                   :password => ENV['LDAP_PWD'] || "behappy"   
})

class User
  include DataMapper::Resource
  property :id,     Integer, :field => "uidnumber", :serial => true
  property :login,     String, :field => "uid", :key => true
  property :hashed_password,  String, :field => "userpassword", :access => :private
  property :name,      String, :field => "cn"

  has n, :group_users, :child_key => [:memberuid]

  def groups
    groups = GroupUser.all(:memberuid => login).collect{ |gu| gu.group }
    def groups.user=(user)
      @user = user
    end
    groups.user = self
    def groups.<<(group)
      unless member? group
        GroupUser.create(:memberuid => @user.login, :gidnumber => group.id)
        super
      end
      self
    end
    def groups.delete(group)
      gu = GroupUser.first(:memberuid => @user.id, :gidnumber => group.id)
      if gu
        gu.destroy
        super
      end
    end
    groups
  end

  dn_prefix { |user| "uid=#{user.login}"}

  treebase "ou=people"

  ldap_properties do |user|
    properties = { :objectclass => ["inetOrgPerson", "posixAccount", "shadowAccount"], :loginshell => "/bin/bash", :gidnumber => "10000" }
    properties[:sn] = "#{user.name.sub(/.*\ /, "")}"
    properties[:givenname] = "#{user.name.sub(/\ .*/, "")}"
    properties[:homedirectory] = "/home/#{user.login}"
    properties
  end

  def password=(password)
    attribute_set(:hashed_password, Ldap::LdapFacade.ssha(password, "--#{Time.now}--#{login}--")) if password
  end
end

class Group
  include DataMapper::Resource
  property :id,       Integer, :serial => true, :field => "gidnumber"
  property :name,     String, :field => "cn"
  
  dn_prefix { |group| "cn=#{group.name}" }
  
  treebase "ou=groups"
  
  ldap_properties {{ :objectclass => "posixGroup"}}

  has n, :users, :child_key => [:gidnumber]
end
 
class GroupUser
  include DataMapper::Resource
 
  dn_prefix { |group_user| "cn=#{group_user.group.name}" }
  
  treebase "ou=groups"
  
  multivalue_field :memberuid
  
  ldap_properties do |group_user|
    {:cn=>"#{group_user.group.name}",  :objectclass => "posixGroup"}
  end
  property :memberuid, String, :key => true#, :field => "memberuid"
  property :gidnumber, Integer, :key => true#, :field => "gidnumber"

  def group
    Group.get!(gidnumber)
  end

  def group=(group)
    gidnumber = group.id
  end

  def user
    User.get!(memberuid)
  end

  def user=(user)
    memberuid = user.login
  end
end
