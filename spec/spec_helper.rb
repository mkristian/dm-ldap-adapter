require 'rubygems'

require 'slf4r/ruby_logger'
gem 'data_objects', "0.9.11"
require 'pathname'
$LOAD_PATH << Pathname(__FILE__).dirname.parent.expand_path + 'lib'

require 'ldap_resource'
#require 'ldap_facade_mock' # uncomment this to use the mock facade
require 'adapters/ldap_adapter'
require 'adapters/memory_adapter'

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.setup(:ldap, {
                   :adapter  => 'ldap',
                   :host => 'localhost',
                   :port => '389',
                   :base => "dc=example,dc=com",
                   :bind_name => "cn=admin,dc=example,dc=com",
                   :password => "behappy"   
})
DataMapper.setup(:memory, {:adapter  => 'memory'})

class User
  include DataMapper::Resource
  property :id,        Integer, :serial => true, :field => "uidnumber"
  property :login,     String, :field => "uid", :unique_index => true
  property :hashed_password,  String, :field => "userpassword", :access => :private
  property :name,      String, :field => "cn"
  property :mail,      String
  property :age,       Integer, :field => "postalcode"
  property :alive,     Boolean, :field => "gecos"

  has n, :roles#, :child_key => [:memberuid]

  has n, :group_users, :child_key => [:memberuid]
#  has n, :groups, :through => :group_users, :mutable => true#, :child_key => [:gidnumber], :parent_key => [:memberuid]

  def groups
    groups = GroupUser.all(:memberuid => id).collect{ |gu| gu.group }
    def groups.user=(user)
      @user = user
    end
    groups.user = self
    def groups.<<(group)
      unless member? group
        GroupUser.create(:memberuid => @user.id, :gidnumber => group.id)
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
    attribute_set(:hashed_password, Ldap::Digest.ssha(password, "--#{Time.now}--#{login}--")) if password
  end
end

class Role
  include DataMapper::Resource
  property :id,       Integer, :serial => true, :field => "gidnumber"
  property :name,     String, :field => "cn"
  
#  multivalue_field "memberuid"
  
  dn_prefix { |role| "cn=#{role.name}" }
  
  treebase "ou=groups"
  
  ldap_properties {{ :objectclass => "posixGroup"}}

  belongs_to :user, :child_key => [:memberuid]
end

class Group
  include DataMapper::Resource
  property :id,       Integer, :serial => true, :field => "gidnumber"
  property :name,     String, :field => "cn"
  
  dn_prefix { |group| "cn=#{group.name}" }
  
  treebase "ou=groups"
  
  ldap_properties {{ :objectclass => "posixGroup"}}

  has n, :users, :child_key => [:gidnumber]
 # has n, :users, :through => :group_users
end
 
class GroupUser
  include DataMapper::Resource
 
  dn_prefix { |group_user| "cn=#{group_user.group.name}" }
  
  treebase "ou=groups"
  
  multivalue_field :memberuid
  
  ldap_properties do |group_user|
    {:cn=>"#{group_user.group.name}",  :objectclass => "posixGroup"}
  end

  #property :id, Integer, :serial => true
  #property :user_id, Integer, :key => true, :field => "memberuid"
  #property :group_id, Integer, :key => true#, :field => "gidnumber"
  property :memberuid, Integer, :key => true#, :field => "memberuid"
  property :gidnumber, Integer, :key => true#, :field => "gidnumber"
#  belongs_to :group, :child_key => [:gidnumber]

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
    memberuid = user.id
  end
#  belongs_to :user, :child_key => [:memberuid]
end
DataMapper.auto_migrate!(:default)
