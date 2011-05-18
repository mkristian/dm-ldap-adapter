# -*- mode: ruby -*-

Gem::Specification.new do |s|
  s.name = %q{dm-ldap-adapter}
  s.version = "0.4.3"

  s.authors = ["mkristian"]
  s.description = %q{ldap adapter for datamapper which uses either net-ldap or ruby-ldap}
  s.email = ["m.kristian@web.de"]
  s.extra_rdoc_files = ["History.txt", "README.txt", "ldap-commands.txt"]
  s.files = ["History.txt", "MIT-LICENSE", "README-example.markdown", "README.txt", "Rakefile", "example/posix.rb", "ldap-commands.txt", "lib/adapters/ldap_adapter.rb", "lib/adapters/noop_transaction.rb", "lib/dummy_ldap_resource.rb", "lib/ldap/array.rb", "lib/ldap/conditions_2_filter.rb", "lib/ldap/digest.rb", "lib/ldap/net_ldap_facade.rb", "lib/ldap/ruby_ldap_facade.rb", "lib/ldap/version.rb", "lib/ldap_resource.rb", "spec/assiociations_ldap_adapter_spec.rb", "spec/authentication_ldap_adapter_spec.rb", "spec/ldap_adapter_spec.rb", "spec/multi_repository_spec.rb", "spec/multi_value_attributes_spec.rb", "spec/sorting_spec.rb", "spec/spec.opts", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/mkristian/dm-ldap-adapter}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{}

  DM_VERSION = ["#{ENV['DM_VERSION'] || '~> 1.0'}"] unless defined? DM_VERSION
  s.add_runtime_dependency(%q<net-ldap>, ["~> 0.2.2"])
  s.add_runtime_dependency(%q<slf4r>, ["~> 0.4.2"])
  s.add_runtime_dependency(%q<dm-core>, DM_VERSION)
  s.add_runtime_dependency(%q<dm-transactions>, DM_VERSION)
  s.add_development_dependency(%q<dm-sqlite-adapter>, DM_VERSION)
  s.add_development_dependency(%q<dm-migrations>, DM_VERSION)
  s.add_development_dependency(%q<rspec>, ["1.3.1"])
  if defined? JRUBY_VERSION
    s.platform = "java"
    s.add_runtime_dependency(%q<jruby-openssl>, ["0.7.2"])
  end
end

