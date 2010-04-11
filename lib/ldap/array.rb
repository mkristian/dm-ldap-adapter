DataMapper::Property::PRIMITIVES.replace(DataMapper::Property::PRIMITIVES.dup + [Array])
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
  module Types
    class LdapArray < DataMapper::Type
      primitive Array
      default Proc.new { |r,p| Ldap::Array.new(r,p).freeze }

      def self.bind(property)
        repository_name = property.repository_name
        model           = property.model
        property_name   = property.name

        model.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{property_name.to_s.plural}=(v)
            attribute_set(:#{property_name}, v)
          end

          def #{property_name.to_s.plural}
            v = attribute_get(:#{property_name})
            case v
            when Ldap::Array
              v
            else
              vv = Ldap::Array.new(self, properties[:#{property_name}])
              vv.replace(v)
            end
          end
        RUBY
      end

      def self.dump(value, property)
        case value
        when String then [value].freeze
        else
          (value || []).freeze
        end
      end

      def self.load(value, property)
        case value
        when String then [value].freeze
        else
          (value || []).freeze
        end
      end
    end
  end
end
