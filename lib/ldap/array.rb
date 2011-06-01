require 'dm-core'
module Ldap
  class Array < ::Array

    def initialize(resource, property,  *args)
      setup(resource, property)
      super(args)
    end

    def setup(resource, property)
      @resource = resource
      @property = property
      self
    end

    alias :push! :push

    def []=(k, v)
      ar = [self].flatten
      ar[k] = v
      @resource.send("#{@property.name}=".to_sym, ar)
      super
    end

    def <<(element)
      push(element)
    end

    def push(element)
      ar = [self].flatten
      ar.push(element)
      @resource.send("#{@property.name}=".to_sym, ar)
      super
    end

   alias :delete! :delete

    def delete(element)
      ar = [self].flatten
      ar.delete(element)
      @resource.send(:"#{@property.name}=", ar)
      super
    end
  end

  class LdapArray < ::DataMapper::Property::Text 
    
    default Proc.new { |r,p| Ldap::Array.new(r,p) }

    def custom?
      true
    end

    def primitive?(value)
      super || value.kind_of?(::Array)
    end

    def load(value)
      result = case value
               when ::String then value[1, value.size-2].split('","').to_a.freeze
               when ::Array then value.freeze
               else
                 []
               end
    end

    def dump(value)
      result = case value
               when LdapArray then '"' + value.join('","') + '"'
               when ::Array then '"' + value.join('","') + '"'
               when ::String then '"' + value.to_s + '"'
               else
                 nil
               end
    end

    # keep the *args so it works for both DM-1.1.x and DM-1.0.x
    def initialize(_model = nil, _name = nil, options = {}, *args)
      super

      add_writer(model,name) unless options[:writer] == :private || options[:accessor] == :private
      add_reader(model,name) unless options[:reader] == :private || options[:accessor] == :private        
    end

    private

    def add_reader(model, name)
      #Creates instance method for reader
      model.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}
         attr_data = attribute_get(:#{name})

         case attr_data
         when Ldap::Array
           attr_data.setup(self, properties[:#{name}])
         else
           new_ldap_array = Ldap::Array.new(self, properties[:#{name}])
           new_ldap_array.replace(attr_data || [])
         end
        end
      RUBY
    end

    def add_writer(model, name)
      #Creates instance method for writer
      model.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}=(input)
          data = case input
          when Ldap::Array
            input.setup(self, properties[:#{name}])
          else
            new_ldap_array = Ldap::Array.new(self, properties[:#{name}])
            new_ldap_array.replace(input || [])
          end

          attribute_set(:#{name}, data)
        end
      RUBY
    end

  end
end
