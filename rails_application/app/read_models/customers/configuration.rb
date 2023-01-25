module Customers
  class Customer < ApplicationRecord
    self.table_name = "customers"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterCustomer, to: [Crm::CustomerRegistered])
      event_store.subscribe(PromoteToVip, to: [Crm::CustomerPromotedToVip])
      event_store.subscribe(UpdatePaidOrdersSummary, to: [Ordering::OrderConfirmed])
      event_store.subscribe(ConnectAccount, to: [Authentication::AccountConnectedToClient])
    end
  end
end
