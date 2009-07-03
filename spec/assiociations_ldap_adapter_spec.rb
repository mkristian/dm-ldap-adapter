$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

[
 :default,
 :ldap,
 :memory
].each do |adapter|
  
  describe "A #{DataMapper.repository(adapter).adapter.class.name}" do
  
    puts "#{DataMapper.repository(adapter).adapter.class.name}"
   
    before do

      DataMapper.repository(adapter) do
        User.all(:login.like => "b%").destroy!
        Group.all(:name.like => "test_%").destroy!
        @user1 = User.create(:login => "black", :name => 'Black', :age => 0)
        @user2 = User.create(:login => "brown", :name => 'Brown', :age => 25)
        @user3 = User.create(:login => "blue", :name => 'Blue',  :age => nil)
 
        @group1 = Group.create(:name => "test_root_group")
        @group2 = Group.create(:name => "test_admin_group")
      end
    end

    after do
      DataMapper.repository(adapter) do
        @user1.destroy
        @user2.destroy
        @user3.destroy

        @group1.destroy
        @group2.destroy
      end
    end

    it 'should successfully save an object' do
      DataMapper.repository(adapter) do
        @group1.new_record?.should be_false
      end
    end

    it 'should be able to get the object' do
      DataMapper.repository(adapter) do
        Group.get(@group1.id).should == @group1
      end
    end

    it 'should be able to get all the objects' do
      DataMapper.repository(adapter) do
        Group.all(:name.like => "test_%").should == [@group1, @group2]
      end
    end

    it 'should be able to have a user' do
      DataMapper.repository(adapter) do
        # the next load prevent strange errors
        @user1 = User.get!(@user1.id)
        @user1.groups << @group1
        @user1.save
        User.get(@user1.id).groups.should == [@group1]
      end
    end

    it 'should be able to delete a user' do
      DataMapper.repository(adapter) do
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
      DataMapper.repository(adapter) do
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
      DataMapper.repository(adapter) do
        # the next load prevent strange errors
        @user1 = User.get!(@user1.id)
        @user1.groups << @group1
        @user1.groups << @group2
        @user1.save
        User.get(@user1.id).groups.sort{|g1, g2| g1.id <=> g2.id}.should == [@group1, @group2]
        @user2.groups << @group1
        @user2.save
      end
      DataMapper.repository(adapter) do
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
      DataMapper.repository(adapter) do
        @user1 = User.get!(@user1.id)
        @user1.groups << @group1
        @user1.groups << @group2
        @user1.groups.sort{|g1, g2| g1.id <=> g2.id}.should == [@group1, @group2]
        @user2.groups << @group1
      end
      DataMapper.repository(adapter) do
        User.get(@user1.id).groups.sort{|g1, g2| g1.id <=> g2.id}.should == [@group1, @group2]
        User.get(@user2.id).groups.should == [@group1]
      end
    end
    
    it 'should be able to delete a user from a group' do
      DataMapper.repository(adapter) do
        size = GroupUser.all.size
        @user1 = User.get!(@user1.id)
        @user1.groups << @group1
        @user1.groups << @group2
        @user2.groups << @group1
        GroupUser.all.size.should == size + 3
      end
      DataMapper.repository(adapter) do
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
end
