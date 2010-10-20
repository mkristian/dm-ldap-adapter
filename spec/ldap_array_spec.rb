$LOAD_PATH << Pathname(__FILE__).dirname.parent.expand_path + 'lib'

require 'ldap/array'
require 'dm-migrations'
require 'dm-sqlite-adapter'

class A
  
  include DataMapper::Resource

  property :id, Serial

  property :list, ::Ldap::LdapArray
end

require 'fileutils'
FileUtils.mkdir_p("target")
DataMapper.setup(:default, 'sqlite3:target/test.sqlite3')
DataMapper.finalize
DataMapper.auto_migrate!(:default)

describe Ldap::LdapArray do

  before :each do
    @resource = A.new
  end

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
end
