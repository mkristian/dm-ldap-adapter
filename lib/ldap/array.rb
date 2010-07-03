#DataMapper::Property::PRIMITIVES.replace(DataMapper::Property::PRIMITIVES.dup + [Array])
module Ldap
  class Array < ::Array

    def initialize(resource, property)
      @resource = resource
      @property = property
      super(0)
    end

    def <<(element)
      push(element)
    end

    alias :push_old :push

    def push(element)
      array = self.dup
      array.push_old(element)
      @resource.attribute_set(@property.name, array)
      array.freeze
    end

    alias :delete_old :delete

    def delete(element)
      array = self.dup
      array.delete_old(element)
      @resource.attribute_set(@property.name, array)
      array.freeze
    end
  end
end

module DataMapper
  class Property
    class LdapArray < Text 
      
#      default Proc.new { |r,p| Ldap::Array.new(r,p).freeze }

      def custom?
        true
      end

      def primitive?(value)
        super || value.kind_of?(::Array)
      end

      def load(value)
        result = 
        case value
          when ::String then value.gsub(/^.|.$/,'').split('","').to_a.freeze
          when ::Array then value.freeze
          else
            nil
        end
puts "load"
p value.class
p value
        p result
puts
        result
      end

      def dump(value)
        result = 
        case value
          when ::Array then '"' + value.join('","') + '"'
          when ::String then '"' + value.to_s + '"'
          else
            nil
        end
puts "dump"
p value
p value.class
        p result
puts
        result
      end

      # primitive String#Array
      # default Proc.new { |r,p| Ldap::Array.new(r,p).freeze }

      # def self.bind(property)
      #   repository_name = property.repository_name
      #   model           = property.model
      #   property_name   = property.name

      #   # model.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      #   #   def #{property_name.to_s.plural}=(v)
      #   #     attribute_set(:#{property_name}, v)
      #   #   end

      #   #   def #{property_name.to_s.plural}
      #   #     v = attribute_get(:#{property_name})
      #   #     case v
      #   #     when Ldap::Array
      #   #       v
      #   #     else
      #   #       vv = Ldap::Array.new(self, properties[:#{property_name}])
      #   #       vv.replace(v)
      #   #     end
      #   #   end
      #   # RUBY
      # end

      # def self.typecast(value, property)
      #   puts "typecast"
      #   p value
      #   p property
      #   value
      # end

      # def self.dump(value, property)
      #   puts "dump"
      #   p value
      #   result = case value
      #   when String then '"' + value.to_s + '"'
      #   else
      #     '"' + (value || []).join('","') + '"'
      #   end
      #   p result
      #   result
      # end

      # def self.from_string(value)
      #   case value
      #   when Array then value
      #   else
      #     (value || '').gsub(/^.|.$/,'').split('","').to_a
      #   end
      # end

      # def self.load(value, property)
      #   puts "load"
      #   p value
      #   result =  value || from_string(value)
      #   p result
      #   result
      # end
    end
  end
end
