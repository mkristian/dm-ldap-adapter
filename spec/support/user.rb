class User
  include DataMapper::Resource
  property :id,        Serial, :field => "uidnumber"
  property :login,     String, :field => "uid", :unique_index => true
  property :hashed_password,  String, :field => "userPassword", :writer => :private
  property :name,      String, :field => "cn"
  property :mail,      String
  property :age,       Integer, :field => "postalCode"
  property :alive,     Boolean, :field => "gecos"

  has n, :roles

  has n, :group_users

  def groups
    groups = GroupUser.all(:user_id => login).collect{ |gu| gu.group }

    def groups.user=(user)
      @user = user
    end

    groups.user = self

    def groups.<<(group)
      unless member? group
        GroupUser.create(:user_id => @user.login, :group_id => group.id)
        super
      end
      self
    end

    def groups.delete(group)
      gu = GroupUser.first(:user_id => @user.login, :group_id => group.id)
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
    salt = "--#{Time.now}--#{login}--"
    attribute_set(:hashed_password, Ldap::Digest.ssha(password, salt)) if password
  end
end
