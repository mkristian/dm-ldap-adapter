posix accounts/groups example
=============================

first you need to adjust the configuration for ldap adapter in `example/posix.rb` and then start irb

    $ LDAP_PWD='secret' irb

     require 'example/posix.rb'
     u = User.create(:login=>'test', :name => "name", :password => "pwd")
     User.all
     g = Group.create(:name => "test")
     Group.all
     u.groups << g
     u.groups
     g.users
     u.authenticate("wrong-pwd")
     u.authenticate("pwd")
