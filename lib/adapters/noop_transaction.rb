require "dm-core"

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
  end
end
