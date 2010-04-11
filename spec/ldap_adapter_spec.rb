$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

describe DataMapper::Adapters::LdapAdapter do

  before(:each) do
    DataMapper.repository(:ldap) do
      User.all.destroy!
      @user1 = User.create(:login => "black", :name => 'Black', :age => 0)
      @user2 = User.create(:login => "brown", :name => 'Brown', :age => 25)
      @user3 = User.create(:login => "blue", :name => 'Blue',  :age => nil)
    end
  end

  it 'should create an uid' do
    class User
      # put the assert here
      dn_prefix { |user| user.id.should_not == nil; "uid=#{user.login}"}
    end

    DataMapper.repository(:ldap) do
      id = @user1.id
      @user1.destroy
      @user1 = User.create(:login => "black", :name => 'Black', :age => 0)
      @user1.id.should_not == id
    end
  end

  it 'should successfully save an object' do
    DataMapper.repository(:ldap) do
      @user1.new?.should be_false
      User.first(:login => @user1.login).new?.should be_false
    end
  end

  it 'should raise an error when trying to create an entity with already used key' do
    DataMapper.repository(:ldap) do
      #p User.first(:login => "black")
      lambda { User.create(:login => "black", :name => 'Black', :age => 0) }.should raise_error
      #p User.all
    end
  end

  it 'should be able to get all the objects' do
    DataMapper.repository(:ldap) do
      User.all(:login.like => "b%").should == [@user1, @user2, @user3]
    end
  end

  it 'should be able to search with empty result' do
    DataMapper.repository(:ldap) do
      User.all(:name => "blablublo").should == []
    end
  end

  it 'should be able to search for objects with equal value' do
    DataMapper.repository(:ldap) do
      User.all(:name => "Brown").should == [@user2]
      User.all(:age => 25).should == [@user2]
    end
  end

  it 'should be able to search for objects included in an array of values' do
    DataMapper.repository(:ldap) do
      User.all(:age => [ 25, 50, 75, 100 ]).should == [@user2]
    end
  end

  #it 'should be able to search for objects included in a range of values' do
  #  User.all(:age => 25..100).should == [@user2]
  #end

  it 'should be able to search for objects with nil value' do
    DataMapper.repository(:ldap) do
      User.all(:age => nil, :name.like => "B%").should == [@user3]
    end
  end

  it 'should be able to search for objects with not equal value' do
    DataMapper.repository(:ldap) do
      User.all(:age.not => 25, :name.like => "B%").should == [@user1, @user3]
    end
  end

  it 'should be able to search for objects not included in an array of values' do
    DataMapper.repository(:ldap) do
      User.all(:age.not => [ 25, 50, 75, 100 ], :name.like => "B%").should == [@user1, @user3]
    end
  end

  it 'should be able to search for objects with not equal value' do
    DataMapper.repository(:ldap) do
      User.all(:age.not => nil, :name.like => "B%").should == [@user1, @user2]
    end
  end

  it 'should search objects with or conditions' do
    DataMapper.repository(:ldap) do
      User.all(:age.not => nil, :conditions => ["name='Black' or name='Blue'"]).should == [@user1]
      User.all(:age.not => nil, :conditions => ["name='Black' or name='Brown'"]).should == [@user1, @user2]
      User.all(:age => nil, :conditions => ["name='Black' or name='Brown'"]).should == []
      User.all(:age => nil, :conditions => ["name='Black' or name='Brown' or name='Blue'"]).should == [@user3]
      User.all(:conditions => ["name='Black' or name='Brown' or name='Blue'"]).should == [@user1, @user2, @user3]
      User.all(:conditions => ["name='Black'"]).should == [@user1]
      User.all(:conditions => ["name like 'Bl%'"]).should == [@user1, @user3]
      User.all(:conditions => ["name like 'B%'"]).should == [@user1, @user2, @user3]
      User.all(:conditions => ["name like 'X%X_X'"]).should == []
      User.all(:conditions => ["name like 'Bla%' or name like 'Br%'"]).should == [@user1, @user2]
    end
  end


  #     it 'should be able to search for objects not included in a range of values' do
  #       User.all(:age.not => 25..100).should == [@user1, @user3]
  #     end

  #    it 'should be able to search for objects with not nil value' do
  #      User.all(:age.not => 25, :name.like => "B%").should == [@user1, @user2]
  #    end

  it 'should be able to search for objects that match value' do
    DataMapper.repository(:ldap) do
      User.all(:name.like => 'Bl%').should == [@user1, @user3]
    end
  end

  #it 'should be able to search for objects with value greater than' do
  #  User.all(:age.gt => 0).should == [@user2]
  #end

  #it 'should be able to search for objects with value greater than or equal to' do
  #  User.all(:age.gte => 0).should == [@user1, @user2]
  #end

  #it 'should be able to search for objects with value less than' do
  #  User.all(:age.lt => 1).should == [@user1]
  #end

  #it 'should be able to search for objects with value less than or equal to' do
  #  User.all(:age.lte => 0).should == [@user1]
  #end

  it 'should be able to update an object' do
    DataMapper.repository(:ldap) do
      @user1 = User.get(@user1.id)
      @user1.age = 10
      @user1.save
      User.get(@user1.id).age.should == 10
      @user1.age = 70
      @user1.save
      User.get(@user1.id).age.should == 70
    end
  end

  it 'should be able to update an object with nil' do
    DataMapper.repository(:ldap) do
      begin
        @user1 = User.get(@user1.id)
        @user1.age = nil
        @user1.save
        User.get(@user1.id).age.should be_nil
        @user1.age = 70
        @user1.save
        User.get(@user1.id).age.should == 70
      rescue => e
        puts e
        puts e.backtrace.join "\n\t"
        raise e
      end
    end
  end

  it 'should be able to destroy an object' do
    DataMapper.repository(:ldap) do
      size = User.all.size
      @user1.destroy
      User.all.size.should == size - 1
    end
  end

  it 'should work with transactions' do
    DataMapper.repository(:ldap) do
      begin
        User.transaction do
          user = User.get(@user3.id)
          user.name = "B new"
          user.save
          User.get(@user3.id).name.should == 'B new'
        end
      rescue => e
        puts e
        puts e.backtrace.join "\n\t"
        raise e
      end
    end
  end

  if DataMapper.repository(:ldap).adapter.respond_to? :open_ldap_connection

    it 'should use one connection for several actions' do
      DataMapper.repository(:ldap) do
        DataMapper.repository.adapter.open_ldap_connection do
          hash = DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash
          User.all
          DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash.should == hash
          user = User.get(@user3.id)
          DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash.should == hash
          user.name = "another name"
          user.save
          DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash.should == hash
        end
        DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash.should_not == hash
      end
    end

    it 'should use new connection for each action' do
      DataMapper.repository(:ldap) do
        hash = DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash
        User.all

        DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash.should_not == hash
        user = User.get(@user3.id)
        DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash.should_not == hash
        user.name = "yet another name"
        user.save
        DataMapper.repository.adapter.instance_variable_get(:@ldap_connection).current.hash.should_not == hash
      end
    end
  end
end

\
