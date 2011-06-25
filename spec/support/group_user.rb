class GroupUser
  include DataMapper::Resource

  dn_prefix { |group_user| "cn=#{group_user.group.name}" }

  treebase "ou=groups"

  multivalue_field :memberUid

  ldap_properties do |group_user|
    {:cn=>"#{group_user.group.name}",  :objectclass => "posixGroup"}
  end

  property :user_id, String, :key => true, :field => "memberUid"
  property :group_id, Integer, :key => true, :field => "gidNumber"

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