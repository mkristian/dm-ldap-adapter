$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

describe DataMapper.repository(:ldap).adapter do

  describe 'user authentication' do

    before do
      DataMapper.repository(:ldap) do
        @user = User.new(:login => "beige", :name => 'Beige')
        @user.password = "asd123"
        @user.save
      end
    end

    after do
      DataMapper.repository(:ldap) do
        @user.destroy
      end
    end

    it 'should successfully authenticate' do
      DataMapper.repository(:ldap) do
        @user.authenticate("asd123").should be_true
        @user.password = "asd"
        @user.save
        @user.authenticate("asd").should be_true
      end
    end

    it 'should not authenticate' do
      DataMapper.repository(:ldap) do
        @user.authenticate("asdasd").should be_false
      end
    end
  end
end
