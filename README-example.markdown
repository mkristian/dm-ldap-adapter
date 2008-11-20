posix accounts/groups example
=============================

first you need to adjust the configuration for ldap adapter in `example/posix.rb` and then start irb

    $ irb
    irb(main):001:0> load 'example/posix.rb'
    irb(main):002:0> u = User.create(:login=>'test', :name => "name", :password => "pwd")
    irb(main):003:0> User.all
    irb(main):004:0> g = Group.create(:name => "test")
    irb(main):005:0> Group.all
    irb(main):006:0> u.groups << g
    irb(main):007:0> u.groups
    irb(main):008:0> u.authenticate("wrong-pwd")
    irb(main):009:0> u.authenticate("pwd")

