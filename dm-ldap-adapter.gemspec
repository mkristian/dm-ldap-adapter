# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-ldap-adapter}
  s.version = "0.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["mkristian"]
  s.date = %q{2011-02-08}
  s.description = %q{ldap adapter for datamapper which uses either net-ldap or ruby-ldap}
  s.email = ["m.kristian@web.de"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt", "ldap-commands.txt"]
  s.files = ["History.txt", "MIT-LICENSE", "README-example.markdown", "README.txt", "Rakefile", "example/posix.rb", "ldap-commands.txt", "lib/adapters/ldap_adapter.rb", "lib/adapters/noop_transaction.rb", "lib/dummy_ldap_resource.rb", "lib/ldap/array.rb", "lib/ldap/conditions_2_filter.rb", "lib/ldap/digest.rb", "lib/ldap/net_ldap_facade.rb", "lib/ldap/ruby_ldap_facade.rb", "lib/ldap/version.rb", "lib/ldap_resource.rb", "spec/assiociations_ldap_adapter_spec.rb", "spec/authentication_ldap_adapter_spec.rb", "spec/ldap_adapter_spec.rb", "spec/multi_repository_spec.rb", "spec/multi_value_attributes_spec.rb", "spec/sorting_spec.rb", "spec/spec.opts", "spec/spec_helper.rb"]
  s.homepage = %q{http://dm-ldap-adapter.rubyforge.org}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-net-ldap>, ["= 0.0.4"])
      s.add_runtime_dependency(%q<slf4r>, [">= 0"])
      s.add_runtime_dependency(%q<dm-core>, ["~> 1.0.0"])
      s.add_development_dependency(%q<hoe>, [">= 2.8.0"])
    else
      s.add_dependency(%q<ruby-net-ldap>, ["= 0.0.4"])
      s.add_dependency(%q<slf4r>, [">= 0"])
      s.add_dependency(%q<dm-core>, ["~> 1.0.0"])
      s.add_dependency(%q<hoe>, [">= 2.8.0"])
    end
  else
    s.add_dependency(%q<ruby-net-ldap>, ["= 0.0.4"])
    s.add_dependency(%q<slf4r>, [">= 0"])
    s.add_dependency(%q<dm-core>, ["~> 1.0.0"])
    s.add_dependency(%q<hoe>, [">= 2.8.0"])
  end
end

