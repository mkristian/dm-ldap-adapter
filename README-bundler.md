# no Gemfile.lock on git #

there are two references for different DM versions

* ~> 1.1.0

* ~> 1.0.0

with a simple symbolic link you can switch between these two profiles.

`$ ln -s Gemfile.lock.1.1.0 Gemfile.lock`

for that reason Gemfile.lock in not on github, so the script run-all.sh

# run specs #

`$ bundle exec spec spec`

or (needs jruby and ruby-maven gem)

`$ rmvn test`
`$ rmvn test --Djruby.version=1.6.1 -Djruby.switches=--1.9`

# build gem

for the ruby platform

`$ gem build dm-ldap-adapter.gemspec`

or for java platform (needs jruby and ruby-maven gem)

`$ rmvn package`

gem will be inside target/dm-ldap-adapter directory.
