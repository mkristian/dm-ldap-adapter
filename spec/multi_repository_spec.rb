require 'spec_helper'

class Order
  include DataMapper::Resource

  property :id, Serial

  belongs_to :user, :required => false, :repository => :ldap
end

class Order2
  include DataMapper::Resource

  def self.repository_name
    :default
  end

  property :id, Serial

  belongs_to :user, :required => false
end

class User
  def self.repository_name
    :ldap
  end
end

Order.auto_migrate!(:default)
Order2.auto_migrate!(:default)

describe DataMapper.repository(:ldap).adapter do

  describe 'belongs_to association' do

    before do
      DataMapper.repository(:ldap) do
        begin
          User.all.destroy!
        @user = User.new(:login => "beige", :name => 'Beige')
        @user.password = "asd123"
        @user.save
        rescue => e
          puts e.backtrace.join("\n\t")
          raise e
        end
      end
    end

    after do
      DataMapper.repository(:ldap) do
        @user.destroy
      end
      @order.destroy
    end

    it 'should create and load the association' do
      @order = Order.create
      @order.user = @user
      @order.save
      order = Order.get!(@order.id)
      DataMapper.repository(:ldap) do
        order.user.should == @user
      end
    end
    it 'should create and load the association with fixed repositories' do
      DataMapper.repository(:default) do
        DataMapper.repository(:ldap) do
          @order = Order2.create
          @order.user = @user
          @order.save
          order = Order2.get!(@order.id)
          order.user.should == @user
        end
      end
    end
  end
end
