module Command
  class RemoveItemFromBasket < Base
    attr_accessor :order_id
    attr_accessor :product_id

    validates :order_id, presence: true
    validates :product_id, presence: true

    alias :aggregate_id :order_id
  end
end
