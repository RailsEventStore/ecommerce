module Deals
  class Deal < ApplicationRecord
    self.table_name = "deals"
  end

  private_constant :Deal

  class Customer < ApplicationRecord
    self.table_name = "deals_customers"
  end

  private_constant :Customer

  def self.deals_for_store(store_id)
    Deal.where(store_id: store_id)
  end

  class EventHandler
    def call(event)
      case event
      when Pricing::OfferDrafted
        Deal.create!(uid: event.data.fetch(:order_id))
      when Stores::OfferRegistered
        find_deal(event).update!(store_id: event.data.fetch(:store_id))
      when Crm::CustomerRegistered
        Customer.find_or_create_by!(customer_id: event.data.fetch(:customer_id)).update!(name: event.data.fetch(:name))
      when Crm::CustomerAssignedToOrder
        find_deal(event).update!(customer_name: find_customer(event).name)
      when Processes::TotalOrderValueUpdated
        find_deal(event).update!(value: event.data.fetch(:discounted_amount))
      when Fulfillment::OrderRegistered
        find_deal(event).update!(stage: "Pending Payment", order_number: event.data.fetch(:order_number))
      when Fulfillment::OrderConfirmed
        find_deal(event).update!(stage: "Won")
      when Fulfillment::OrderCancelled
        find_deal(event).update!(stage: "Lost")
      when Pricing::OfferExpired
        find_deal(event).update!(stage: "Lost")
      end
    end

    private

    def find_deal(event)
      Deal.find_by!(uid: event.data.fetch(:order_id))
    end

    def find_customer(event)
      Customer.find_by!(customer_id: event.data.fetch(:customer_id))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(EventHandler.new, to: [
        Pricing::OfferDrafted,
        Stores::OfferRegistered,
        Crm::CustomerRegistered,
        Crm::CustomerAssignedToOrder,
        Processes::TotalOrderValueUpdated,
        Fulfillment::OrderRegistered,
        Fulfillment::OrderConfirmed,
        Fulfillment::OrderCancelled,
        Pricing::OfferExpired
      ])
    end
  end
end
