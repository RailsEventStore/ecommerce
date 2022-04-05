# frozen_string_literal: true

require 'securerandom'

module Crm
  module Actions
    module Customers
      class Index < Action::Base
        include Deps['repositories.customers']

        def handle(req, res)
          res.status = 200
          res.body = { customers: customers.all.map(&:to_h) }
        end
      end
    end
  end
end
