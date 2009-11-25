$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

describe DataMapper.repository(:ldap).adapter do
  
  describe 'belongs_to association' do
    
    before do
      DataMapper.repository(:ldap) do
        User.all.destroy!
        @user1 = User.create(:login => "black", :name => 'Black', :mail => "blackmail@exmple.com", :age => 100) 
        @user2 = User.create(:login => "brown", :name => 'brown', :mail => "brownmail@exmple.com", :age => 25)
        @user3 = User.create(:login => "blue", :name => 'Yellow')
        @user4 = User.create(:login => "baluh", :name => 'Hmm')
      end
    end
    
    after do
      DataMapper.repository(:ldap) do
        @user1.destroy
        @user2.destroy
        @user3.destroy
        @user4.destroy
      end
    end
    
    it 'should sort descending without order option' do
      DataMapper.repository(:ldap) do
        expected = User.all().sort do |u1, u2|
          u1.id <=> u2.id
        end
        User.all.should == expected
      end
    end

    it 'should sort descending with order option' do
      DataMapper.repository(:ldap) do
        expected = User.all().sort do |u1, u2|
          u1.login <=> u2.login
        end
        User.all(:order => [:login]).should == expected
      end
    end
    it 'should sort case insensitive with order option' do
      DataMapper.repository(:ldap) do
        expected = User.all().sort do |u1, u2|
          u1.name.upcase <=> u2.name.upcase
        end
        User.all(:order => [:name]).should == expected
      end
    end

    it 'should sort with nil values' do
      DataMapper.repository(:ldap) do
        users = User.all(:order => [:mail]).select { |u| !u.mail.nil? }
        users.should == [@user1, @user2]
      end
    end
  end
end
