$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

[
 :default,
 :ldap, 
 :memory
].each do |adapter|

  puts "#{DataMapper.repository(adapter).adapter.class.name}"
  
  describe "A #{DataMapper.repository(adapter).adapter.class.name}" do

    before do
      DataMapper.repository(adapter) do
        @user1 = User.create(:login => "black", :name => 'Black', :age => 0) 
        @user2 = User.create(:login => "brown", :name => 'Brown', :age => 25)
        @user3 = User.create(:login => "blue", :name => 'Blue',  :age => nil)
      end
    end
    
    after do
      DataMapper.repository(adapter) do
        @user1.destroy
        @user2.destroy
        @user3.destroy
      end
    end

    it 'should successfully save an object' do
      DataMapper.repository(adapter) do
        @user1.new_record?.should be_false
        User.first(:login => @user1.login).new_record?.should be_false
      end
    end

    it 'should be able to get the object' do
      DataMapper.repository(adapter) do
        User.get(@user1.id).should == @user1
      end
    end

    it 'should be able to get all the objects' do
      DataMapper.repository(adapter) do
        User.all(:login.like => "b%").should == [@user1, @user2, @user3]
      end
    end

    it 'should be able to search for objects with equal value' do
      DataMapper.repository(adapter) do
        User.all(:name => "Brown").should == [@user2]
        User.all(:age => 25).should == [@user2]
      end
    end

    it 'should be able to search for objects included in an array of values' do
      DataMapper.repository(adapter) do
        User.all(:age => [ 25, 50, 75, 100 ]).should == [@user2]
      end
    end

    #it 'should be able to search for objects included in a range of values' do
    #  User.all(:age => 25..100).should == [@user2]
    #end

    it 'should be able to search for objects with nil value' do
      DataMapper.repository(adapter) do
        User.all(:age => nil, :name.like => "B%").should == [@user3]
      end
    end

    if adapter != :default
      it 'should be able to search for objects with not equal value' do
        DataMapper.repository(adapter) do
          User.all(:age.not => 25, :name.like => "B%").should == [@user1, @user3]
        end
      end
      
      it 'should be able to search for objects not included in an array of values' do
        DataMapper.repository(adapter) do
          User.all(:age.not => [ 25, 50, 75, 100 ], :name.like => "B%").should == [@user1, @user3]
        end
      end
    else
      puts
      puts "NOTE"
      puts "=================================================="
      puts
      puts "sqlite3 handles NULL different from values, i.e."
      puts "select * from users where name = 'sd';"
      puts "and"
      puts "select * from users where name != 'sd';"
      puts "gives the same result when all names are NULL !!!"
      puts
      puts "=================================================="
      puts
    end

    it 'should be able to search for objects with not equal value' do
      DataMapper.repository(adapter) do
        User.all(:age.not => nil, :name.like => "B%").should == [@user1, @user2]
      end
    end

    #     it 'should be able to search for objects not included in a range of values' do
    #       User.all(:age.not => 25..100).should == [@user1, @user3]
    #     end

    #    it 'should be able to search for objects with not nil value' do
    #      User.all(:age.not => 25, :name.like => "B%").should == [@user1, @user2]
    #    end

    it 'should be able to search for objects that match value' do
      DataMapper.repository(adapter) do
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
      DataMapper.repository(adapter) do
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
      DataMapper.repository(adapter) do
        @user1 = User.get(@user1.id)
        @user1.age = nil
        @user1.save
        User.get(@user1.id).age.should be_nil
        @user1.age = 70
        @user1.save
        User.get(@user1.id).age.should == 70
      end
    end

    it 'should be able to destroy an object' do
      DataMapper.repository(adapter) do
        size = User.all.size
        @user1.destroy
        User.all.size.should == size - 1
      end
    end

    it 'should work with transactions' do
      DataMapper.repository(adapter) do
        User.transaction do
          user = User.get(@user3.id)
          user.name = "B new"
          user.save
          User.get(@user3.id).name.should == 'B new'
        end
      end
    end

    if DataMapper.repository(adapter).adapter.respond_to? :ldap_connection
    
    it 'should use one connection for several actions' do
      DataMapper.repository(adapter) do
        DataMapper.repository.adapter.ldap_connection.open do
          hash = DataMapper.repository.adapter.ldap_connection.current.hash
          User.all
          DataMapper.repository.adapter.ldap_connection.current.hash.should == hash
          user = User.get(@user3.id)
          DataMapper.repository.adapter.ldap_connection.current.hash.should == hash
          user.name = "another name"
          user.save
          DataMapper.repository.adapter.ldap_connection.current.hash.should == hash
        end
        DataMapper.repository.adapter.ldap_connection.current.hash.should_not == hash
      end
    end

    it 'should use new connection for each action' do
      DataMapper.repository(adapter) do
        hash = DataMapper.repository.adapter.ldap_connection.current.hash
        User.all

        DataMapper.repository.adapter.ldap_connection.current.hash.should_not == hash
        user = User.get(@user3.id)
        DataMapper.repository.adapter.ldap_connection.current.hash.should_not == hash
        user.name = "yet another name"
        user.save
        DataMapper.repository.adapter.ldap_connection.current.hash.should_not == hash
      end
    end
end
  end
end
