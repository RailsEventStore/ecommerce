module Orders
  class SubmitService < ApplicationService
    def initialize(order_id:, customer_id:)
      @order_id = order_id
      @customer_id = customer_id
    end

    def call
      success = true
      unavailable_products = []

      event_store
        .within { submit_order }
        .subscribe(to: Processes::ReservationProcessFailed) do |event|
          success = false
          unavailable_products << Products::Product.where(id: event.data.fetch(:unavailable_products)).pick(:name)
        end
        .call

      if success
        Result.new(:success)
      else
        Result.new(:products_out_of_stock, unavailable_products)
      end
      rescue Ordering::Order::IsEmpty
        Result.new(:order_is_empty)
      rescue Crm::Customer::NotExists
        Result.new(:customer_not_exists)
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
