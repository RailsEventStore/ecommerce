module Customers
  class Customer < ApplicationRecord
    self.table_name = "customers"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterCustomer.new, to: [Crm::CustomerRegistered])
      event_store.subscribe(PromoteToVip.new, to: [Crm::CustomerPromotedToVip])
      event_store.subscribe(UpdatePaidOrdersSummary.new, to: [Ordering::OrderConfirmed])
      event_store.subscribe(ConnectAccount.new, to: [Authentication::AccountConnectedToClient])
    end
  end
end
