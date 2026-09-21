module Ordering
  class CreateDraftReturn
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :return_id, :order_id, :returnable_products

    alias aggregate_id return_id

    def initialize(return_id, order_id, returnable_products)
      @return_id = return_id
      @order_id = order_id
      products = returnable_products.map do |product|
        product_id = product.fetch(:product_id)
        quantity = product.fetch(:quantity)
        [
          { product_id: product_id, quantity: quantity },
          product.is_a?(Hash) && UUID.match?(product_id) && quantity.instance_of?(Integer)
        ]
      end
      @returnable_products = products.map(&:first)
      valid = returnable_products.is_a?(Array) && products.all?(&:last) && UUID.match?(@return_id) && UUID.match?(@order_id)
    rescue KeyError, NoMethodError, TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  CreateDraftRefund = CreateDraftReturn
end
