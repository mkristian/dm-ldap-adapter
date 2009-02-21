= dm-ldap-adapter

*Homepage*:  [http://dm-ldap-adapter.rubyforge.org]

*Git*:       [http://github.com/mkristian/dm-ldap-adapter]

*Author*:    Kristian Meier  

*Copyright*: 2008-2009

== DESCRIPTION:

=== usecase

the usecase for that implementation was using an ldap server for user authentication and authorization. the ldap server is configured to have posixAccounts and posixGroups. on the datamapper side these accounts/groups are modeled with many-to-many relationship. further more the model classes should be in such a way that they can be used with another repository as well, i.e. they carry some ldap related configuration but this is only relevant for the ldap-adapter.

=== low level ldap library

the ldap library which does the actual ldap protocol stuff is [http://rubyforge.org/projects/net-ldap] and it is hidden behind a facade, so one could replace it with a different library or make it pluggable.

=== examples

see 'example/posix.rb' for user/group setup works with default installation of openldap on ubuntu (just change your password as needed in the code)

the 'example/identity_maps.rb' shows the usage of identity maps, see also below.

== FEATURES/PROBLEMS:

* the net-ldap has some issues with not closing the connections when an exception/error got raised

* error from the ldap server are only logged and do not raise any exceptions (to be changed in next release)

== SYNOPSIS:

=== distinguished name (DN) of a model

there are three parts which makes the DN of a model, the base from the ldap conncetion, the `treebase` of the model and `dn_prefix` of an instance.

    class User
      include DataMapper::Resource
      property :id, Serial, :field => "uidnumber"
      dn_prefix { |user| "uid=#{user.login}"}
      treebase "ou=people"
    end

with a base `dc=example,dc=com` we get a DN like the user 'admin'

    uid=admin,ou=people,dc=example,dc=com

=== ldap entities are bigger than the model

for example the ldap posixGroup has more attributes than the model class, it needs the `objectclass` attribute set to `posixGroup`.

    class Group
      include DataMapper::Resource
      property :id, Serial, :field => "gidnumber"
      property :name,     String, :field => "cn"
      dn_prefix { |group| "cn=#{group.name}" }
      treebase "ou=groups"
      ldap_properties {{ :objectclass => "posixGroup"}}
    end

so with the help of the `ldap_properties` you can define a block which returns an hash with extra attributes. with such block you can make some calculations if needed, i.e. :homedirectory => "/home/#{login}" for the posixAccount.

=== authentication

this uses the underlying bind of a ldap connection. so on any model where you have the `dn_prefix` and the `treebase` configured, you can call the method `authenticate(password)`. this will forward the request to the ldap server.

=== queries

conditions in ldap depend on the attributes definition in the ldap schema. here is the list of what is working with that ldap adapter side and the usual AND between the conditions:  
                                                               
* :eql
* :not
* :like
* :in
* Range

not working are `:lt, :lte, :gt, :gte`

*note*: sql handles `NULL` different from values, i.e.

     select * from users where name = 'sd';

and

     select * from users where name != 'sd';

gives the same result when *all* names are `NULL` !!!

=== multiple repositories

most probably you have to work with ldap as one repository and a database as a second repository. for me it worked best to define the `default_repository` for each model in the model itself:

    class User
      . . .     
      def self.default_repository_name
        :ldap
      end
    end

    class Config
      . . .   
      def self.default_repository_name
        :db
      end
    end

if you want to benefit from the advantages of the identidy maps you need to wrap your actions for *merb* see http://www.datamapper.org/doku.php?id=docs:identity_map or for *rails* put an `around_filter` inside application.rb

     around_filter :repositories
     
     def repositories
       DataMapper.repository(:ldap) do
         DataMapper.repository(:db) do
           yield
         end 
       end 
     end

and to let the ldap resources use the ldap respository it is best to bind it to that repository like this

  class User
    . . .
    def self.repository_name
      :ldap
    end
  end
   
=== transactions

the adapter offers a noop transaction, i.e. you can wrap everything into a transaction but the ldap part has no functionality.

*note*: the ldap protocol does not know transactions

=== many-to-many associations

staying with posix example there the groups has a memberuid attribute BUT unlike with relational databases it can have multiple values. to achieve a relationship with these values the underlying adapter needs to know that this specific attribute needs to be handled differently. for this `multivalue_field` comes into play. the ldap adapter clones the model and places the each memberuid in its own clone.

    class GroupUser
      include DataMapper::Resource    
      property :memberuid, String, :key => true
      property :gidnumber, Integer, :key => true
      dn_prefix { |group_user| "cn=#{group_user.group.name}" }
      treebase "ou=groups"
      ldap_properties do |group_user|
        {:cn=>"#{group_user.group.name}",  :objectclass => "posixGroup"}
      end
    
      multivalue_field :memberuid
          
    end

== REQUIREMENTS:

* slf4r the logging facade
* net-ldap pure ruby ldap library
* logging (optional) if logging via logging is desired
* log4r (optional) if logging via log4r is desired

== INSTALL:

* sudo gem install dm-ldap-adapter

== LICENSE:

(The MIT License)

Copyright (c) 2009 Kristian Meier

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
