require "dm-core"
require 'slf4r'

module DataMapper
  module Adapters
    class NoopTransaction
      
      def close ; end
      def begin ; end
      def prepare ; end
      def commit ; end
      def rollback ; end
      def rollback_prepared ; end
      
    end
    class SimpleAdapter < AbstractAdapter

      include Slf4r::Logger

      # @see AbstractAdapter
      def transaction_primitive
        NoopTransaction.new
      end

      def initialize(name, uri_or_options)
        super(name, uri_or_options)
      end

      protected
      
      # checks whether a given resource fullfils the conditions
      # @param [DataMapper::Resource] resource
      # @param [Array<Condition>] conditions
      # @return [Boolean] 
      #   true if the resource are within the conditions otherwise false
      def filter_resource(resource, conditions)
        #puts "condi"
        #p conditions
        # no conditation => no filter
        if conditions.size == 0
          true
        else
          conditions.all? do |tuple|
            operator, property, bind_value = *tuple
            
            value = property.get!(resource)
            case operator
            when :eql, :in then equality_comparison(bind_value, value)
            when :not      then !equality_comparison(bind_value, value)
            when :like     then Regexp.new(bind_value.gsub(/%/, ".*")) =~ value
            when :gt       then !value.nil? && value >  bind_value
            when :gte      then !value.nil? && value >= bind_value
            when :lt       then !value.nil? && value <  bind_value
            when :lte      then !value.nil? && value <= bind_value
            else raise "Invalid query operator: #{operator.inspect}"
            end
          end
        end
      end

      # helper method to dispatch the equality test for different
      # classes
      def equality_comparison(bind_value, value)
        case bind_value
          when Array, Range then bind_value.include?(value)
          when NilClass     then value.nil?
          else                   bind_value == value
        end
      end

      public

      # @see AbstractAdapter
      # @param [Array<DataMapper::Resources>] resources
      #   aaaa
      # @return [Fixnum] 
      #    number of the newly created resources
      def create(resources)
        resources.select do |resource|

          create_resource(resource)

        end.size # just return the number of create resources
      end

      # @see AbstractAdapter
      # @param [Hash] attributes
      #   collection of attribute, i.e. the name/value pairs which 
      #   needs to be updated
      # @param [Query] 
      #   on all resources which are selected by that query the 
      #   update will be applied
      # @return [Fixnum] 
      #   number of the updated resources
      def update(attributes, query)
        read_many(query).select do |resource|
          
          update_resource(resource, attributes)

        end.size
      end

      # @see AbstractAdapter
      # @param [DataMapper::Query] query
      #    which selects the resource
      # @return [DataMapper::Resource] 
      #    the found Resource or nil
      def read_one(query)
        result = read_resource(query)
        if result.is_a? Resource
          result
        elsif result # assume result to be Array with the values
          #puts "------------------"
          #p result
          query.model.load(result, query)
        end
      end
      
      # @see AbstractAdapter
      # @param [DataMapper::Query] query
      #   which selects the resources
      # @return [DataMapper::Collection] 
      #   collection of Resources
      def read_many(query)
        Collection.new(query) do |set|
          result = read_resources(query)
#puts "read_many"
#p result
          if result.size > 0 and result.first.is_a? Resource
            set.replace(result)
          else
            result.each do |values|
              set.load(values)
            end
          end
        end
      end

      # @see AbstractAdapter
      # @param [Query] query
      #   which selects the resources to be deleted
      # @return [Fixnum]
      #   number of the deleted resources
      def delete(query)
        read_many(query).each do |resource|

          delete_resource(resource)

        end.size
      end
      
      private

      # @param [DataMapper::Resource] resource
      #   which will be created
      # @return [DataMapper::Resource] 
      #   either the resource itself if the creation was successful or nil 
      def create_resource(resource)
        raise NotImplementedError.new
      end

      # @param [DataMapper::Query] query
      #   which selects the resource
      # @return [DataMapper::Resource,Array<String>] 
      #   the resource or a set of values ordered in the same manner as query.fields attributes
      def read_resource(query)
        raise NotImplementedError.new
      end

      # @param [DataMapper::Query] query
      #   which selects the resources
      # @return [Array<DataMapper::Resource>,Array<String>]
      #   resources or ordered values 
      # @see #read_resource
      def read_resources(query)
        raise NotImplementedError.new
      end

      # @param [DataMapper::Resource] resource
      #   which will be updated with the given attributes.
      # @param [Hash] attributes 
      #    the keys are the property names and the values are the new values of that property. 
      # @return [DataMapper::Resource] 
      #   resource on success otherwise nil
      def update_resource(resource, attributes)
        raise NotImplementedError.new
      end

      # @param [DataMapper::Resource] resource
      #   which will be deleted
      # @return [DataMapper::Resource]
      #   either the resource if the deletion was successful or nil 
      def delete_resource(resource)
        raise NotImplementedError.new
      end
    end
  end
end
