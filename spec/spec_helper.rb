require 'rubygems'

require 'slf4r/ruby_logger'
Slf4r::LoggerFacade4RubyLogger.level = :info

require 'dm-sqlite-adapter'
require 'dm-migrations'
require 'dm-transactions'
require 'pathname'
$LOAD_PATH << Pathname(__FILE__).dirname.parent.expand_path + 'lib'

print "datamapper version:"
puts DataMapper::VERSION

require 'ldap_resource'
require 'adapters/ldap_adapter'

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.setup(:ldap, {
                   :adapter  => 'ldap',
                   :host => 'localhost',
                   :port => '389',
                   :base => "dc=example,dc=com",
                   :facade => (ENV['FACADE'] || :net_ldap).to_sym,
                   :bind_name => "cn=admin,dc=example,dc=com",
                   :password => "secret"
})

module DataMapper
  module Resource
    class State

      # a persisted/deleted resource
      class Deleted < Persisted
        def set(subject, value)
          warn 'Deleted resource cannot be modified ' + subject.inspect + ' ' + value.to_s + " " + @resource.inspect
          super
        end
      end
    end
  end
end
class User
  include DataMapper::Resource
  property :id,        Serial, :field => "uidnumber"
  property :login,     String, :field => "uid", :unique_index => true
  property :hashed_password,  String, :field => "userpassword", :writer => :private
  property :name,      String, :field => "cn"
  property :mail,      String
  property :age,       Integer, :field => "postalcode"
  property :alive,     Boolean, :field => "gecos"

  has n, :roles

  has n, :group_users

  def groups
    groups = GroupUser.all(:user_id => id).collect{ |gu| gu.group }
    def groups.user=(user)
      @user = user
    end
    groups.user = self
    def groups.<<(group)
      unless member? group
        GroupUser.create(:user_id => @user.id, :group_id => group.id)
        super
      end
      self
    end
    def groups.delete(group)
      gu = GroupUser.first(:user_id => @user.id, :group_id => group.id)
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
  property :id,       Serial, :field => "gidnumber"
  property :name,     String, :field => "cn"

  dn_prefix { |role| "cn=#{role.name}" }

  treebase "ou=groups"

  ldap_properties {{:objectclass => "posixGroup"}}

  belongs_to :user
end

class Group
  include DataMapper::Resource
  property :id,       Serial, :field => "gidnumber"
  property :name,     String, :field => "cn"

  dn_prefix { |group| "cn=#{group.name}" }

  treebase "ou=groups"

  ldap_properties {{:objectclass => "posixGroup"}}
end

class GroupUser
  include DataMapper::Resource

  dn_prefix { |group_user| "cn=#{group_user.group.name}" }

  treebase "ou=groups"

  multivalue_field :memberuid

  ldap_properties do |group_user|
    {:cn=>"#{group_user.group.name}",  :objectclass => "posixGroup"}
  end

  property :user_id, Integer, :key => true, :field => "memberuid"
  property :group_id, Integer, :key => true, :field => "gidnumber"

  def group
    Group.get!(group_id)
  end

  def group=(group)
    group_id = group.id
  end

  def user
    User.get!(user_id)
  end

  def user=(user)
    user_id = user.id
  end
end
DataMapper.auto_migrate!(:default)
