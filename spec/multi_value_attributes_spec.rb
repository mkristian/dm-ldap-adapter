$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

class Contact
  include DataMapper::Resource

  property :id,        Integer, :serial => true, :field => "uidnumber"
  property :login,     String, :field => "uid", :unique_index => true
  property :hashed_password,  String, :field => "userpassword", :access => :private
  property :name,      String, :field => "cn"
  property :mail,      LdapArray

  dn_prefix { |contact| "uid=#{contact.login}"}

  treebase "ou=people"

  ldap_properties do |contact|
    properties = { :objectclass => ["inetOrgPerson", "posixAccount", "shadowAccount"], :loginshell => "/bin/bash", :gidnumber => "10000" }
    properties[:sn] = "#{contact.name.sub(/.*\ /, "")}"
    properties[:givenname] = "#{contact.name.sub(/\ .*/, "")}"
    properties[:homedirectory] = "/home/#{contact.login}"
    properties
  end

  def password=(password)
    attribute_set(:hashed_password, Ldap::Digest.ssha(password, "--#{Time.now}--#{login}--")) if password
  end
end

describe DataMapper.repository(:ldap).adapter.class do

  describe 'belongs_to association' do

    before do
      DataMapper.repository(:ldap) do
#p Contact.all
        @contact = Contact.new(:login => "beige", :name => 'Beige')
        @contact.password = "asd123"
        @contact.save
      end
    end

    after do
      DataMapper.repository(:ldap) do
        @contact.destroy
      end
    end

    it 'should create and load the association' do
       DataMapper.repository(:ldap) do
        @contact.mail.should == []
        @contact.mail << "email1"
        @contact.save
        @contact = Contact.get!(@contact.id)
        @contact.mail.should == ["email1"]
        @contact.mail << "email2"
        @contact.save
        @contact = Contact.get!(@contact.id)
        @contact.mail.should == ["email1", "email2"]
        @contact.mail.delete("email1")
        @contact.save
        @contact = Contact.get!(@contact.id)
        @contact.mail.should == ["email2"]
      end
    end
  end
end
