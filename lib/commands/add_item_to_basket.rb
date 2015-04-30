module Commands
  class AddItemToBasket < Command
    attr_reader :order_id
    attr_reader :product_id

    validates :order_id, presence: true
    validates :product_id, presence: true

    alias :aggregate_id :order_id

    def initialize(order_id, product_id)
      @order_id = order_id
      @product_id = product_id
    end
  end
end
