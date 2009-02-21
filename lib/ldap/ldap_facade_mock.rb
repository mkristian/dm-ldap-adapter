module Ldap
  class LdapFacade

    def self.open(config)
      puts "open"
      p config
      puts
      yield "dummy"
    end

    def initialize(uri)
      puts "new #{self.hash}"
      p uri
      puts
    end

    def create_object(treebase, dn_prefix, key_field, props, silence = false)
      options = { :dn_prefix => dn_prefix, 
        :treebase => treebase, 
        :key_field => key_field, 
        :properties => props }
      puts "create #{self.hash}"
      p options
      puts
      @@count ||= 0
      @@count += 1
    end

    def read_objects(treebase, key_field, conditions, many = false)
      options = { :treebase => treebase, 
        :key_field => key_field,
        :conditions => conditions, :many => many }
      puts "read #{self.hash}"
      p options
      puts
      [] if many
    end

    def update_object(treebase, dn_prefix, actions)
      options = { :dn_prefix => dn_prefix, 
        :treebase => treebase, 
        :actions => actions }
      puts "update #{self.hash}"
      p options
      puts
    end

    def delete_object(treebase, dn_prefix)
      options = { :dn_prefix => dn_prefix, 
        :treebase => treebase }
      puts "delete #{self.hash}"
      p options
      puts
    end
  end
end
