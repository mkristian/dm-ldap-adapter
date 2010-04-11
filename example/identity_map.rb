require 'example/posix.rb'

USER_REPO = :default

class User

  def self.ddefault_repository_name
    USER_REPO
  end

  def self.repository_name
    USER_REPO
  end

  def authenticate(pwd)
    require 'base64'
    Base64.encode64(Digest::SHA1.digest(pwd)).gsub(/\n/, '') == attribute_get(:hashed_password)[5,1000]
  end
end

class GroupUser

  def self.ddefault_repository_name
    USER_REPO
  end

  def self.repository_name
    USER_REPO
  end

end

class Group

  def self.ddefault_repository_name
    USER_REPO
  end

  def self.repository_name
    USER_REPO
  end

end

require 'adapters/memory_adapter'
DATA_REPO=:store
DataMapper.setup(DATA_REPO, {:adapter  => 'memory'})

class Item
  include DataMapper::Resource
  property :id, Serial
end


DataMapper.repository(USER_REPO) do |repository|
  repository.adapter.open_ldap_connection do
    DataMapper.repository(DATA_REPO) do
      root = User.first(:login => 'root') || User.create(:id => 0, :login => :root, :name => 'root', :password => 'none') if root.nil?
      admin = Group.first(:name => 'admin') || Group.create(:name => 'admin')
      root.groups << admin

      p DataMapper.repository(USER_REPO).identity_map(User)

      p DataMapper.repository(USER_REPO).identity_map(Group)

      p root.authenticate('none')

      p root.groups

      (1..10).each {Item.create}

      p DataMapper.repository(DATA_REPO).identity_map(Item)
    end
  end
end
