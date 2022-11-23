module Customers
  class Customer < ApplicationRecord
    self.table_name = "customers"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterCustomer, to: [Crm::CustomerRegistered])
      event_store.subscribe(PromoteToVip, to: [Crm::CustomerPromotedToVip])
    end
  end
end
