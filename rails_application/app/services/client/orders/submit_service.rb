module Client
  module Orders
    class OrderHasUnavailableProducts < StandardError
      attr_reader :unavailable_products

      def initialize(unavailable_products)
        @unavailable_products = unavailable_products
      end
    end

    class SubmitService < ApplicationService
      def initialize(order_id:, customer_id:)
        @order_id = order_id
        @customer_id = customer_id
      end

      def call
        unavailable_products = []
        event_store
          .within { submit_order }
          .subscribe(to: Processes::ReservationProcessFailed) do |event|
            unavailable_products = Products::Product.where(id: event.data.fetch(:unavailable_products)).pluck(:name)
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
          command_bus.(Ordering::SubmitOrder.new(order_id: order_id))
          command_bus.(Crm::AssignCustomerToOrder.new(order_id: order_id, customer_id: customer_id))
        end
      end
    end
  end
end
