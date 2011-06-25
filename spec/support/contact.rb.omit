class Contact
	include DataMapper::Resource

	def self.auto_upgrade!(args = nil)
		DataMapper.logger.warn("Skipping #{self.name}.auto_upgrade!")
	end

	def self.default_repository_name
		:ldap
	end

	def self.repository_name
		:ldap
	end
	
	property :id,						Serial, :field => 'uid'
	property :cn,						String, :required => true
	property :salutation,					String, :lazy => [:view]
	property :title,					String, :lazy => [:view]
	property :givenname,					String
	property :sn,						String, :required => true
	property :o,						String
	property :postaladdress,				String, :lazy => [:view]
	property :postalcode,					String, :lazy => [:view]
	property :l,						String
	property :st,						String, :lazy => [:view]
	property :c,						String, :lazy => [:view]
	property :telephonenumber,				String
	property :facsimiletelephonenumber,			String, :lazy => [:view]
	property :pager,					String, :lazy => [:view]
	property :jpegphoto,					LdapArray, :lazy => true
	property :mobile,					String, :lazy => [:view]
	property :anniversary,					String, :lazy => [:view]
	property :mail,						LdapArray
	property :labeleduri,					LdapArray, :lazy => [:view]
	property :marker,					LdapArray, :lazy => [:view]
	property :description,					LdapArray, :lazy => [:view]

	dn_prefix do |u|
		"uid=#{u.id}"
	end

	ldap_properties do |u|
          properties = { :objectclass => ['inetOrgPerson']}#, "posixAccount", "shadowAccount"]}#'contactPerson'] }
		properties
	end

	treebase 'ou=people'

	before :save, :fix_object

private

	def fix_object
		self.cn = "#{self.givenname} #{self.sn}".strip
	end

end
