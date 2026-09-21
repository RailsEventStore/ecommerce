module Crm
  class AssignCustomerToOrder
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :customer_id, :order_id
    alias aggregate_id order_id

    def initialize(customer_id, order_id)
      @customer_id = customer_id
      @order_id = order_id
      valid = [@customer_id, @order_id].all? { |id| id.is_a?(String) && UUID.match?(id) }
      raise Infra::Command::Invalid unless valid
    end
  end
end
