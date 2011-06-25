require 'spec_helper'

describe DataMapper.repository(:ldap).adapter.class do

  describe 'LdapArray' do

    before :each do
      DataMapper.repository(:ldap) do
        begin
          TestContact.all(:login.like => "b%").destroy!
          @contact =  TestContact.new(:login => "beige", :name => 'Beige')
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

        @contact.mail = ["email1"]
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.get!(@contact.id)
        @contact.mail.should == ["email1"]
        @contact.mail << "email2"
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.get!(@contact.id)
        @contact.mail.should == ["email1", "email2"]
        @contact.mail.delete("email1")
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.get!(@contact.id)
        @contact.mail.should == ["email2"]

        mail = @contact.mail.dup
        mail.delete("email2")
        @contact.mail = mail
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.get!(@contact.id)
        @contact.mail.should == []
      end
    end

    it 'should get an LdapArray on retrieving collection' do
      DataMapper.repository(:ldap) do
        @contact.mail.should == []

        @contact.mail = ["email1"]
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.all.detect {|c| c.id = @contact.id}
        @contact.mail.should == ["email1"]

        @contact.mail = @contact.mail.dup << "email2"
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.all.detect {|c| c.id = @contact.id}
        @contact.mail.should == ["email1", "email2"]

        mail = @contact.mail.dup
        mail.delete("email1")
        @contact.mail = mail
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.all.detect {|c| c.id = @contact.id}
        @contact.mail.should == ["email2"]

        mail = @contact.mail.dup
        mail.delete("email2")
        @contact.mail = mail
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.all.detect {|c| c.id = @contact.id}
        @contact.mail.should == []
      end
    end

    it 'should allow to replace the LdapArray' do
      DataMapper.repository(:ldap) do
        @contact = TestContact.get(@contact.id)
        @contact.mail.should == []
        @contact.mail = ['foo', 'bar']
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.get(@contact.id)
        @contact.mail.should == ['foo', 'bar']
      end
    end
    it 'should create resource with the LdapArray' do
      DataMapper.repository(:ldap) do
        @contact = TestContact.new(:login => "black", :name => 'Black')
        @contact.password = "asd123"
        @contact.mail = ['foo', 'bar']
        @contact.save
      end
      DataMapper.repository(:ldap) do
        @contact = TestContact.get(@contact.id)
        @contact.mail.should == ['foo', 'bar']
      end
    end

    it 'should be able to search properties with LdapArray' do
      DataMapper.repository(:ldap) do
        @contact.mail = ["email1"]
        @contact.save
        TestContact.all(:mail => "email1").first.should == @contact
      end
    end

    it 'should be able to use multilines with LdapArray' do
      DataMapper.repository(:ldap) do
        @contact.mail = ["email1\nmail2\nmail2\nmail4", "email1"]
        @contact.save
        TestContact.get(@contact.id).mail.should == ["email1\nmail2\nmail2\nmail4", "email1"]
      end
    end
  end
end
