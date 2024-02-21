# frozen_string_literal: true

module Crm
  module Repositories
    class Customers < Repository[:crm_customers]
      commands :create

      def all
        crm_customers.to_a
      end

      def find(id)
        crm_customers.by_pk(id).one!
      end
    end
  end
end
