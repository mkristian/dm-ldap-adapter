require 'spec_helper'

describe DataMapper::Adapters::LdapAdapter do

  before do
    DataMapper.repository(:ldap) do
      User.all(:login.like => "b%").destroy!
      Group.all(:name.like => "test_%").destroy!
      
      #First we create some items.
      user1 = User.create(:login => "black", :name => 'Black', :age => 0)
      user2 = User.create(:login => "brown", :name => 'Brown', :age => 25)
      user3 = User.create(:login => "blue", :name => 'Blue',  :age => nil)

      group1 = Group.create(:name => "test_root_group")
      group2 = Group.create(:name => "test_admin_group")
      
      #Then we retrive the items we created earlier and use them for tests.
      @user1 = User.get!(user1.id)
      @user2 = User.get!(user2.id)
      @user3 = User.get!(user3.id)
      
      @group1 = Group.get!(group1.id)
      @group2 = Group.get!(group2.id)      
    end
  end
  
  after(:all) do
    DataMapper.repository(:ldap) do
      User.all(:login.like => "b%").destroy!
      Group.all(:name.like => "test_%").destroy!
    end
  end
  
  it 'should have valid testing data' do
    @user1.should be_a_kind_of(User)
    @user2.should be_a_kind_of(User)
    @user3.should be_a_kind_of(User)
    @group1.should be_a_kind_of(Group)
    @group2.should be_a_kind_of(Group)
  end

  it 'should successfully save an object' do
    DataMapper.repository(:ldap) do
      @group1.new?.should be_false
    end
  end

  it 'should be able to get the object' do
    DataMapper.repository(:ldap) do
      Group.get(@group1.id).should == @group1
    end
  end

  it 'should be able to get all the objects' do
    DataMapper.repository(:ldap) do
      Group.all(:name.like => "test_%").should == [@group1, @group2]
    end
  end

  it 'should be able to have a user' do
    DataMapper.repository(:ldap) do
      begin
        gu = GroupUser.new(:user_id => @user1.id, :group_id => @group1.id)
        # the next load prevent strange errors
        @user1 = User.get!(@user1.id)
        @user1.groups << @group1
        @user1.save
        User.get(@user1.id).groups.should == [@group1]
      rescue => e
        puts e
        puts e.backtrace.join "\n\t"
        raise e
      end
    end
  end

  it 'should be able to delete a user' do
    DataMapper.repository(:ldap) do
      # the next load prevent strange errors
      @user1 = User.get!(@user1.id)
      @user1.groups << @group1
      @user1.save
      @user1.groups.delete(@group1)
      @user1.save
      User.get(@user1.id).groups.should == []
      @user1.groups << @group1
      @user1.groups << @group2
      @user1.save
      @user1.groups.delete(@group1)
      @user1.save
      User.get(@user1.id).groups.should == [@group2]
    end
  end

  it 'should be able to have users and remove them again' do
    DataMapper.repository(:ldap) do
      # the next load prevent strange errors
      @user1 = User.get!(@user1.id)
      @user1.groups << @group1
      @user1.save
      User.get(@user1.id).groups.should == [@group1]
      @user1.groups << @group2
      @user1.save
      User.get(@user1.id)
      @user1.groups.sort{|g1, g2| g1.id <=> g2.id}.should == [@group1, @group2]
      @user1.groups.delete(@group1)
      @user1.save
      User.get(@user1.id).groups.should == [@group2]
      @user1.groups.delete(@group2)
      @user1.save
      User.get(@user1.id).groups.should == []
    end
  end

  it 'should be able to have two users' do
    DataMapper.repository(:ldap) do
      # the next load prevent strange errors
      @user1 = User.get!(@user1.id)
      @user1.groups << @group1
      @user1.groups << @group2
      @user1.save
      User.get(@user1.id).groups.sort{|g1, g2| g1.id <=> g2.id}.should == [@group1, @group2]
      @user2.groups << @group1
      @user2.save
    end
    DataMapper.repository(:ldap) do
      User.get(@user2.id).groups.should == [@group1]
      User.get(@user1.id).groups.sort{|g1, g2| g1.id <=> g2.id}.should == [@group1, @group2]
    end
  end

  it 'should raise an not found error' do
    lambda do
      User.get!(4711)
    end.should raise_error(DataMapper::ObjectNotFoundError)
  end

  it 'should be able to have two users in one group' do
    DataMapper.repository(:ldap) do
      @user1 = User.get!(@user1.id)
      @user1.groups << @group1
      @user1.groups << @group2
      @user1.groups.sort{|g1, g2| g1.id <=> g2.id}.should == [@group1, @group2]
      @user2.groups << @group1
    end
    DataMapper.repository(:ldap) do
      User.get(@user1.id).groups.sort{|g1, g2| g1.id <=> g2.id}.should == [@group1, @group2]
      User.get(@user2.id).groups.should == [@group1]
    end
  end

  it 'should be able to delete a user from a group' do
    DataMapper.repository(:ldap) do
      size_before = GroupUser.all.size

      @user1.groups << @group1
      GroupUser.all.size.should == size_before+1
  
      @user1.groups << @group2
      GroupUser.all.size.should == size_before+2

      @user2.groups << @group1
      GroupUser.all.size.should == size_before+3
    end
    DataMapper.repository(:ldap) do
      @user1 = User.get!(@user1.id)
      @user1.groups.delete(@group1)
      User.get(@user1.id).groups.should == [@group2]
      User.get(@user2.id).groups.should == [@group1]
      @user2 = User.get!(@user2.id)
      @user2.groups.delete(@group1)
      User.get(@user1.id).groups.should == [@group2]
      User.get(@user2.id).groups.should == []
    end
  end

end
