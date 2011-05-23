#!/bin/bash

run_bundler() {
    ruby=$1
    shift
    for version in $@ ; do
	echo
	echo "-----------------------------------"
	echo "run specs with $ruby"
	echo "datamapper base version $version"
	echo "ldap facade $FACADE"
	echo "-----------------------------------"
	rm -f Gemfile.lock
	ln -s Gemfile.lock.$version Gemfile.lock
	($ruby -S bundle exec spec spec)
    done
}

run_maven(){
    jruby_versions=$1
    shift
    for version in $@ ; do
	echo
	echo "-----------------------------------"
	echo "run specs with ruby-maven"
	echo "jruby version $jruby_versions"
        echo "datamapper base version $version"
	echo "-----------------------------------"
	rm -f Gemfile.lock
	rm -f Gemfile.pom
	ln -s Gemfile.lock.$version Gemfile.lock
	rm -rf target/rubygems
	rmvn spec spec -- -Djruby.18and19 -Djruby.versions=$jruby_versions
    done
}

# iterate over all supported jruby versions
VERSIONS='1.0.0 1.1.0'
run_maven 1.5.6,1.6.1 $VERSIONS || exit -1

# take only the latest (j)ruby version (on ubuntu naming convnetion)
run_bundler 'jruby --1.8' $VERSIONS || exit -1
#TODO run_bundler 'jruby --1.9' $VERSIONS || exit -1
for f in net_ldap ruby_ldap ; do
    export FACADE=$f
    run_bundler 'ruby1.8' $VERSIONS || exit -1
    run_bundler 'ruby1.9.1' $VERSIONS || exit -1
done

rmvn package -- -DskipSpecs
cp target/dm-ldap-adapter/dm-ldap-adapter-*-java.gem .
gem build dm-ldap-adapter.gemspec
