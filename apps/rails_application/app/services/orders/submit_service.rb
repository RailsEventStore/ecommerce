module Orders
  class SubmitService
    def initialize(order_id, customer_id)
      @order_id = order_id
      @customer_id = customer_id
    end

    def call
      event_store
        .within { submit_order }
        .subscribe(method(:record_result), to: [
          Pricing::EmptyOrderAcceptanceRejected,
          Pricing::OfferRejected,
          Fulfillment::OrderRegistered
        ])
        .call

      result
    end

    private

    attr_reader :order_id, :customer_id, :result

    def record_result(event)
      @result = event if event.data.fetch(:order_id) == order_id
    end

    def submit_order
      ActiveRecord::Base.transaction do
        command_bus.(Pricing::RequestOrderAcceptance.new(order_id))
        unless result.instance_of?(Pricing::EmptyOrderAcceptanceRejected)
          command_bus.(Crm::AssignCustomerToOrder.new(customer_id, order_id))
        end
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
