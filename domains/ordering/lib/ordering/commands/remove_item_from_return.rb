module Ordering
  class RemoveItemFromReturn
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :return_id, :order_id, :product_id

    alias aggregate_id return_id

    def initialize(return_id, order_id, product_id)
      @return_id = return_id
      @order_id = order_id
      @product_id = product_id
      valid = UUID.match?(@return_id) && UUID.match?(@order_id) && UUID.match?(@product_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  RemoveItemFromRefund = RemoveItemFromReturn
end
