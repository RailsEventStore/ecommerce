module Orders
  class OrderHasUnavailableProducts < StandardError
    attr_reader :unavailable_products

    def initialize(unavailable_products)
      @unavailable_products = unavailable_products
    end
  end

  class SubmitService
    def self.call(...)
      new(...).call
    end

    def initialize(order_id:, customer_id:)
      @order_id = order_id
      @customer_id = customer_id
    end

    def call
      unavailable_products = []
      event_store
        .within { submit_order }
        .subscribe(to: Pricing::OfferRejected) do |event|
          unavailable_products = Products.product_names_for_ids(event.data.fetch(:unavailable_product_ids))
        end
        .call

      if unavailable_products.any?
        raise OrderHasUnavailableProducts.new(unavailable_products)
      end
    end

    private

    attr_reader :order_id, :customer_id

    def submit_order
      ActiveRecord::Base.transaction do
        command_bus.(Pricing::AcceptOffer.new(order_id: order_id))
        command_bus.(Crm::AssignCustomerToOrder.new(order_id: order_id, customer_id: customer_id))
      end
    end

    def event_store
      Rails.configuration.event_store
    end

    def command_bus
      Rails.configuration.command_bus
    end
  end
end
