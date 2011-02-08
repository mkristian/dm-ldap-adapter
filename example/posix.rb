require 'pathname'
require 'rubygems'
require 'slf4r/logger'
require 'slf4r/ruby_logger'
require 'dm-core'

$LOAD_PATH << Pathname(__FILE__).dirname.parent.expand_path + 'lib'

# Logging.init :debug, :info, :warn, :error

# appender = Logging::Appender.stdout
# appender.layout = Logging::Layouts::Pattern.new(:pattern => "%d [%-l] (%c) %m\n")
# logger = Logging::Logger.new(:root)
# logger.add_appenders(appender)
# logger.level = :debug
# logger.info "initialized logger . . ."

dummy = true  #uncomment this to use dummy, i.e. a database instead of ldap
dummy = false # uncomment this to use ldap
unless dummy
  require 'ldap_resource'

  # comment this out if you want to use "net/ldap"
  require 'ldap/ruby_ldap_facade'

  require 'adapters/ldap_adapter'

  DataMapper.setup(:default, {
                     :adapter  => 'ldap',
                     :host => 'localhost',
                     :port => '389',
                     :base => ENV['LDAP_BASE'] || "dc=example,dc=com",
                     :bind_name => "cn=admin," + (ENV['LDAP_BASE'] || "dc=example,dc=com"),
                     :password => ENV['LDAP_PWD'] || "behappy"
                   })
else
  require 'dummy_ldap_resource'
  DataMapper.setup(:default, 'sqlite3::memory:')
  adapter = DataMapper.repository.adapter
  def adapter.ldap_connection
    con = Object.new
    def con.open
      yield
    end
    con
  end
end

class User
  include DataMapper::Resource

  property :id,        Serial, :field => "uidNumber"
  property :login,     String, :field => "uid"
  property :hashed_password,  String, :field => "userPassword"
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
      gu = GroupUser.first(:memberuid => @user.login, :gidnumber => group.id)
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
    attribute_set(:hashed_password, Ldap::Digest.sha(password)) if password
  end
end

class Group
  include DataMapper::Resource
  include Slf4r::Logger
  property :id,       Serial, :field => "gidNumber"
  property :name,     String, :field => "cn"

  dn_prefix { |group| "cn=#{group.name}" }

  treebase "ou=groups"

  ldap_properties {{ :objectclass => "posixGroup"}}

  def users
    users = GroupUser.all(:gidnumber => id).collect{ |gu| gu.user }
    def users.group=(group)
      @group = group
    end
    users.group = self
    def users.<<(user)
      unless member? user
        GroupUser.create(:memberuid => user.login, :gidnumber => @group.id)
        super
      end
      self
    end
    def users.delete(user)
      gu = GroupUser.first(:memberuid => user.login, :gidnumber => @group.id)
      if gu
        gu.destroy
        super
      end
    end
    users
  end
end

class GroupUser
  include DataMapper::Resource
  include Slf4r::Logger

  dn_prefix { |group_user| "cn=#{group_user.group.name}" }

  treebase "ou=groups"

  multivalue_field :memberuid

  ldap_properties do |group_user|
    {:cn=>"#{group_user.group.name}",  :objectclass => "posixGroup"}
  end
  property :memberuid, String, :key => true#, :field => "memberUid"
  property :gidnumber, Integer, :key => true#, :field => "gidNumber"

  def group
    Group.get!(gidnumber)
  end

  def group=(group)
    gidnumber = group.id
  end

  def user
    User.first(:login => memberuid)
  end

  def user=(user)
    memberuid = user.login
  end
end

if dummy
  DataMapper.auto_migrate!
end
