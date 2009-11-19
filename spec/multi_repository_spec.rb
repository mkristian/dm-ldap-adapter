$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

class Order
  include DataMapper::Resource

  property :id, Serial

  repository(:ldap) do
    belongs_to :user
  end
end

Order.auto_migrate!(:default)

describe DataMapper.repository(:ldap).adapter do

  describe 'belongs_to association' do

    before do
      DataMapper.repository(:ldap) do
        @user = User.new(:login => "beige", :name => 'Beige')
        @user.password = "asd123"
        @user.save
      end

      @order = Order.create
    end

    after do
      DataMapper.repository(:ldap) do
        @user.destroy
      end
      @order.destroy
    end

    it 'should create and load the association' do
      @order.user = @user
      @order.save
      Order.get!(@order.id).user.should == @user
    end
  end
end
