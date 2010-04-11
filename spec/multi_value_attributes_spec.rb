$LOAD_PATH << File.dirname(__FILE__)
require 'spec_helper'

class Contact
  include DataMapper::Resource

  property :id,        Serial, :field => "uidnumber"
  property :login,     String, :field => "uid", :unique_index => true
  property :hashed_password,  String, :field => "userpassword", :writer => :private, :lazy => true
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

  describe 'LdapArray' do

    before :each do
      DataMapper.repository(:ldap) do
        begin
          Contact.all(:login.like => "b%").destroy!
          @contact =  Contact.new(:login => "beige", :name => 'Beige')
          @contact.password = "asd123"
          @contact.save
        rescue => e
          puts e.backtrace.join("\n\t")
          raise e
        end
      end
    end

    it 'should add many values to a LdapArray' do
       DataMapper.repository(:ldap) do
        @contact.mail.should == []
        @contact.mails.should == []

        @contact.mails << "email1"
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.get!(@contact.id)
        @contact.mail.should == ["email1"]
        @contact.mails.should == ["email1"]
        @contact.mails << "email2"
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.get!(@contact.id)
        @contact.mail.should == ["email1", "email2"]
        @contact.mails.should == ["email1", "email2"]

        @contact.mails.delete("email1")
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.get!(@contact.id)
        @contact.mail.should == ["email2"]
        @contact.mails.should == ["email2"]

        @contact.mails.delete("email2")
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.get!(@contact.id)
        @contact.mail.should == []
        @contact.mails.should == []
      end
    end

    it 'should get an LdapArray on retrieving collection' do
      DataMapper.repository(:ldap) do
        @contact.mail.should == []

        @contact.mail = "email1"
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.all.detect {|c| c.id = @contact.id}
        @contact.mail.should == ["email1"]

        @contact.mails << "email2"
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.all.detect {|c| c.id = @contact.id}
        @contact.mail.should == ["email1", "email2"]

        @contact.mails.delete("email1")
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.all.detect {|c| c.id = @contact.id}
        @contact.mail.should == ["email2"]

        @contact.mails.delete("email2")
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.all.detect {|c| c.id = @contact.id}
        @contact.mail.should == []
      end
    end

    it 'should allow to replace the LdapArray' do
      DataMapper.repository(:ldap) do
        @contact = Contact.get(@contact.id)
        @contact.mail.should == []
        @contact.mail = ['foo', 'bar']
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.get(@contact.id)
        @contact.mail.should == ['foo', 'bar']
      end
    end
    it 'should create resource with the LdapArray' do
      DataMapper.repository(:ldap) do
        @contact = Contact.new(:login => "black", :name => 'Black')
        @contact.password = "asd123"
        @contact.mail = ['foo', 'bar']
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = Contact.get(@contact.id)
        @contact.mail.should == ['foo', 'bar']
      end
    end
  end
end
