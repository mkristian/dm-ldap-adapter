require "dm-core"

module Ldap
  class NoopTransaction
    
    def close ; end
    def begin ; end
    def prepare ; end
    def commit ; end
    def rollback ; end
    def rollback_prepared ; end
    
  end
end

module DataMapper
  module Adapters
    class LdapAdapter
      def transaction_primitive
        ::Ldap::NoopTransaction.new
      end
      def push_transaction(transaction)
        @transaction = transaction
      end

      def pop_transaction
        @transaction
      end
      
      def current_transaction
        @transaction
      end
    end
  end
end
