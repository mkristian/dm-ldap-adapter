require 'spec_helper'

class A
  include DataMapper::Resource

  property :id, Serial
  property :list,         ::Ldap::LdapArray,    :accessor => :public
  property :hidden_list,  ::Ldap::LdapArray,    :accessor => :private
  property :write_list,   ::Ldap::LdapArray,    :reader => :private, :writer => :public
  property :read_list,    ::Ldap::LdapArray,    :reader => :public, :writer => :private
end

require 'fileutils'
FileUtils.mkdir_p("target")
DataMapper.setup(:default, 'sqlite3:target/test.sqlite3')
DataMapper.finalize
DataMapper.auto_migrate!(:default)

describe Ldap::LdapArray do
  before { @resource = A.new }

  it 'should create new with array' do
    @resource.list = ["1", "2"]
    @resource.dirty?.should be_true
    @resource.save
    resource = A.first(:id => @resource.id)
    resource.list.should == ["1", "2"]
    resource.list.class.should == Ldap::Array
  end

  it 'should have empty array on new resource' do
    @resource.list << "1"
    @resource.dirty?.should be_true
    @resource.save
    resource = A.first(:id => @resource.id)
    resource.list.should == ["1"]
    resource.list.class.should == Ldap::Array
  end

  it 'should save after adding an element' do
    @resource.list = ["1", "2"]
    @resource.save
    @resource.list << "4"
    @resource.save
    resource = A.first(:id => @resource.id)
    resource.list.should == ["1", "2", "4"]
    resource.list.class.should == Ldap::Array
  end

  it 'should save after changing an element' do
    @resource.list = ["1", "2"]
    @resource.save
    @resource.list[1] = "4"
    @resource.save
    resource = A.first(:id => @resource.id)
    resource.list.should == ["1", "4"]
    resource.list.class.should == Ldap::Array
  end

  it 'should save after deleting element from list' do
    @resource.list = ["1", "2"]
    @resource.save
    @resource.list.delete("1")
    @resource.save
    resource = A.first(:id => @resource.id)
    resource.list.should == ["2"]
    resource.list.class.should == Ldap::Array
  end
  
  context 'when :accessor property is set to :private' do 
    it 'should not create a write accessor' do
      @resource.should_not respond_to(:hidden_list=)
    end

    it 'should not create a reade accessor' do
      @resource.should_not respond_to(:hidden_list)
    end  
  end

  context 'when :accessor property is set to :public' do 
    it 'should create a write accessor' do
      @resource.should respond_to(:list=)
    end

    it 'should create a reade accessor' do
      @resource.should respond_to(:list)
    end  
  end
  
  context 'when :writer property is set to :public' do
    it 'should create a write accessor' do
      @resource.should respond_to(:write_list=)
    end
  end

  context 'when :writer property is set to :private' do
    it 'should not create a write accessor' do
      @resource.should_not respond_to(:read_list=)
    end
  end

  context 'when :reader property is set to :public' do
    it 'should create a read accessor' do
      @resource.should respond_to(:read_list)
    end
  end

  context 'when :reader property is set to :private' do
    it 'should not create a read accessor' do
      @resource.should_not respond_to(:write_list)
    end
  end

end
