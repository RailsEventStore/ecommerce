module Commands
  class SetOrderAsExpired < Command
    attr_reader :order_id
    validates :order_id, presence: true

    alias :aggregate_id :order_id

    def initialize(order_id)
      @order_id = order_id
    end
  end
end
