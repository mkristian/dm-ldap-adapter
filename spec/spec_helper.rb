#Require main environment
require 'dm-ldap-adapter'

#Require developer depdencies
require 'dm-sqlite-adapter'
require 'dm-migrations'

print "datamapper version:"
puts DataMapper::VERSION

#Logging needs to be cleaned up...
require 'slf4r/ruby_logger'
Slf4r::LoggerFacade4RubyLogger.level = :warn

require 'ldap_resource'

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.setup(:ldap, {
                   :adapter  => 'ldap',
                   :host => 'localhost',
                   :port => '389',
                   :base => "dc=example,dc=com",
                   :facade => (ENV['FACADE'] || :net_ldap).to_sym,
                   :bind_name => "cn=admin,dc=example,dc=com",
                   :password => "behappy"
})

puts "using facade #{(ENV['FACADE'] || :net_ldap).to_sym}"

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

DataMapper.auto_migrate!(:default)


