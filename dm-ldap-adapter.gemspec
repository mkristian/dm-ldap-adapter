# -*- mode: ruby -*-

Gem::Specification.new do |s|
  s.name = %q{dm-ldap-adapter}
  s.version = "0.4.7"

  s.description = %q{ldap adapter for datamapper which uses either net-ldap or ruby-ldap}
  s.authors = ["mkristian", "xertres"]
  s.email = ["m.kristian@web.de", ""]
  s.extra_rdoc_files = ["History.txt", "README.md", "ldap-commands.txt"]

  s.files = ["History.txt", "MIT-LICENSE", "ldap-commands.txt" ] + Dir["README*.md"]
  s.files += Dir['{lib,spec,example}/**/*.rb']

  s.homepage = %q{http://github.com/mkristian/dm-ldap-adapter}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{}

  DM_VERSION = ["#{ENV['DM_VERSION'] || '~> 1.0'}"] unless defined? DM_VERSION
  s.add_runtime_dependency(%q<net-ldap>, ["~> 0.16"])
  s.add_runtime_dependency(%q<slf4r>, ["~> 0.4.2"])
  s.add_runtime_dependency(%q<dm-core>, DM_VERSION)
  s.add_runtime_dependency(%q<dm-transactions>, DM_VERSION)
  s.add_development_dependency(%q<dm-sqlite-adapter>, DM_VERSION)
  s.add_development_dependency(%q<dm-migrations>, DM_VERSION)
  s.add_development_dependency(%q<rspec>, ["~> 2.6"])
  if defined? JRUBY_VERSION
    s.platform = "java"
    s.add_runtime_dependency(%q<jruby-openssl>, ["0.7.2"])
  else
    s.add_development_dependency(%q<ruby-ldap>, ["~> 0.9.11"])
  end
end

