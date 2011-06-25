#This needs some documentation.

module DataMapper
  module Resource
    class State

      # a persisted/deleted resource
      class Deleted < Persisted
        def set(subject, value)
          warn 'Deleted resource cannot be modified ' + subject.inspect + ' ' + value.to_s + " " + @resource.inspect
          super
        end
      end
    end
  end
end