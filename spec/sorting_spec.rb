$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

if Object.const_defined?('LDAP')
  describe DataMapper.repository(:ldap).adapter do
    
    describe 'belongs_to association' do
      
      before do
        DataMapper.repository(:ldap) do
          User.all.destroy!
          @user1 = User.create(:login => "black", :name => 'Black', :age => 0) 
          @user2 = User.create(:login => "brown", :name => 'Brown', :age => 25)
          @user3 = User.create(:login => "blue", :name => 'Blue',  :age => nil)
        end
      end
      
      after do
        DataMapper.repository(:ldap) do
          @user1.destroy
          @user2.destroy
          @user3.destroy
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
    end
  end
else
  puts 'skip sorting spec for non "ruby-ldap" library'
end
