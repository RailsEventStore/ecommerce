module Commands
  class CreateOrder < Command
    attr_reader :order_id
    attr_reader :customer_id

    validates :order_id, presence: true
    validates :customer_id, presence: true

    alias :aggregate_id :order_id

    def initialize(order_id, customer_id)
      @order_id = order_id
      @customer_id = customer_id
    end
  end
end
