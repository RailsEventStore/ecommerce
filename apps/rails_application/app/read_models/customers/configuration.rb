module Customers
  class Customer < ApplicationRecord
    self.table_name = "customers"
  end

  class Order < ApplicationRecord
    self.table_name = "customers_orders"
  end

  private_constant :Customer
  private_constant :Order

  def self.customers_for_store(store_id)
    Customer.where(store_id: store_id)
  end

  def self.find_customer_in_store(customer_id, store_id)
    Customer.where(store_id: store_id).find(customer_id)
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterCustomer.new, to: [Crm::CustomerRegistered])
      event_store.subscribe(RenameCustomer.new, to: [Crm::CustomerRenamed])
      event_store.subscribe(AssignStoreToCustomer.new, to: [Stores::CustomerRegistered])
      event_store.subscribe(PromoteToVip.new, to: [Crm::CustomerPromotedToVip])
      event_store.subscribe(AssignCustomerToOrder.new, to: [Crm::CustomerAssignedToOrder])
      event_store.subscribe(UpdateOrderTotalValue.new, to: [Processes::TotalOrderValueUpdated])
      event_store.subscribe(UpdatePaidOrdersSummary.new, to: [Fulfillment::OrderConfirmed])
      event_store.subscribe(ConnectAccount.new, to: [Authentication::AccountConnectedToClient])
      event_store.subscribe(SetLogin.new, to: [Authentication::LoginSet])
    end
  end
end
