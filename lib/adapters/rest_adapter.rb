require "dm-core"
require 'adapters/simple_adapter'
require 'net/http'
require 'extlib/inflection'
require 'extlib/module'

module DataMapper
  module Adapters
    class RestAdapter < SimpleAdapter

      include ::Slf4r::Logger

      def resource_name_from_model(model)
        ::Extlib::Inflection.underscore(model.name)
      end

      def resource_name_from_query(query)
        resource_name_from_model(query.model)
      end

      def keys_from_query(query)
        keys = query.model.key
        # work around strange missing of properties in model
        # but the query has still the fields :P
        if keys.size == 0
          query.fields.select do |f|
            f.key?
          end
        else
          keys
        end
      end

      def key_value_from_query(query)
        keys = keys_from_query(query)
        logger.debug { "keys=#{keys.inspect}" }
        if keys.size == 1
          key = keys[0]
          # return the third element of the condition array
          # which belongs to the key
          query.conditions.detect do |c|
            c[1] == key
          end[2]
        else
          raise "compound keys are not supported"
        end
      end

      def http_get(uri)
        send_request do |http|
          request = Net::HTTP::Get.new(uri)
          request.basic_auth(@uri[:login], 
                             @uri[:password]) unless @uri[:login].blank?
          http.request(request)
        end
      end

      def http_post(uri, data = nil)
        send_request do |http|
          request = Net::HTTP::Post.new(uri, {
                                          'content-type' => 'application/xml',
                                          'content-length' => data.length.to_s
                                        })
          request.basic_auth(@uri[:login], 
                             @uri[:password]) unless @uri[:login].blank?
          http.request(request, data)
        end
      end

      def http_put(uri, data = {})
        send_request do |http|
          request = Net::HTTP::Put.new(uri)
          request.basic_auth(@uri[:login], 
                             @uri[:password]) unless @uri[:login].blank?
          request.set_form_data(data)
          http.request(request)
        end
      end

      def http_delete(uri)
        send_request do |http|
          request = Net::HTTP::Delete.new(uri)
          request.basic_auth(@uri[:login], 
                             @uri[:password]) unless @uri[:login].blank?
          http.request(request)
        end
      end

      def send_request(&block)
        res = nil
        Net::HTTP.start(@uri[:host], @uri[:port].to_i) do |http|
          res = yield(http)
        end
        logger.debug { "response=" + res.code }
        res
      end

      def parse_resource(xml, model, query = nil)
        elements = {}
        associations = {}
        many_to_many = {}
        xml.elements.collect do |element|
          if element.text.nil? 
            if element.attributes['type'] == 'array'
              many_to_many[element.name.gsub('-','_').to_sym] = element
            else
              associations[element.name.gsub('-','_').to_sym] = element
            end
          else
            elements[element.name.gsub('-','_').to_sym] = element.text
          end
        end
#puts
#puts "elements"
#p elements
        resource = model.load(model.properties.collect do |f|
                                  elements[f.name]
                                end, query)
        resource.send("#{keys_from_query(query)[0].name}=".to_sym, elements[keys_from_query(query)[0].name] )
#p resource
        associations.each do |name, association|          
          model = 
            if rel = model.relationships[name]
              if rel.child_model == model
                rel.parent_model
              else
                rel.child_model
              end
              #                  else
#::Extlib::Inflection.constantize(::Extlib::Inflection.classify(name))
#                    model.find_const(::Extlib::Inflection.classify(name))
            end
          if resource.respond_to? "#{name}=".to_sym
            resource.send("#{name}=".to_sym, 
                          parse_resource(association, model,
                                         ::DataMapper::Query.new(query.repository, model )))
          else
            resource.send(("#{name.to_s.pluralize}<" + "<").to_sym, 
                          parse_resource(association, model,
                                         ::DataMapper::Query.new(query.repository, model )))
          end
        end
        resource.instance_variable_set(:@new_record, false)
        resource
      end

      # @see SimpleAdapter
      def create_resource(resource)
        name = resource.model.name
        uri = "/#{name.pluralize}.xml"
        logger.debug { "post #{uri}" }
        response = http_post(uri, resource.to_xml )
        resource_new = parse_resource(REXML::Document::new(response.body).root, 
                                  resource.model,
                                  ::DataMapper::Query.new(resource.repository, 
                                                          resource.model ))

        # copy all attributes/associations from the downloaded resource
        # to the given resource
        # TODO better pass the given resource into parse_resource
        resource_new.attributes.each do |key, value|
          resource.send(:properties)[key].set!(resource, value)
        end
        resource_new.send(:relationships).each do |key, value|
          resource.send("#{key}=".to_sym, resource_new.send(key))
        end
        resource
      end

      # @see SimpleAdapter
      def read_resource(query)
        if(query.conditions.empty?)
          raise "not implemented"
        else
          key = key_value_from_query(query)
          uri = "/#{resource_name_from_query(query).pluralize}/#{key}.xml"
          logger.debug { "get #{uri}" }
          response = http_get(uri)
          if response.kind_of?(Net::HTTPSuccess)
            parse_resource(REXML::Document::new(response.body).root, 
                           query.model, 
                           query)
          else
            #TODO may act on different response codes differently
          end
        end
      end

      # @see SimpleAdapter
      def read_resources(query)
#        raise "not implemented"
        [read_resource(query)]
      end

      # @overwrite SimpleAdapter
      def update(attributes, query)
        name = resource_name_from_query(query)
        params = {}
        attributes.each do |attr, val|
          params["#{name}[#{attr.name}]"]=val
        end
        key = key_value_from_query(query)
        uri = "/#{name.pluralize}/#{key}.xml"
        logger.debug { "put #{uri}" }
        response = http_put(uri, params)
        response.kind_of?(Net::HTTPSuccess)
      end

      # @see SimpleAdapter
      def update_resource(resource, attributes)
        query = resource.to_query
        if(query.conditions.empty?)
          raise "not implemented"
        else
          name = resource.name
          params = {}
          attributes.each do |attr, val|
            params["#{name}[#{attr.name}]"]=val
          end
          key = key_value_from_query(query)
          logger.debug {resource.to_xml}
          response = http_put("/#{resource_name_from_query(query).pluralize}/#{key}.xml", params)
          response.kind_of?(Net::HTTPSuccess)
        end
      end

      # @overwrite SimpleAdapter
      def delete(query)
        # TODO limit == 1 is NOT sufficient ONLY necessary
        if query.limit == 1 
          name = resource_name_from_query(query)
          key = key_value_from_query(query)
          uri = "/#{name.pluralize}/#{key}.xml"
          logger.debug { "delete #{uri}" }
          response = http_delete(uri)
          response.kind_of?(Net::HTTPSuccess) 
        else
          super
        end
      end

      # @see SimpleAdapter
      def delete_resource(resource)
        name = resource.name
        key = key_value_from_query(resource.to_queryquery)
        uri = "/#{name.pluralize}/#{key}.xml"
        logger.debug { "delete #{uri}" }
        response = http_delete(uri)
        response.kind_of?(Net::HTTPSuccess) 
      end
    end
  end
end
