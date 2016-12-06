module Command
  class SubmitOrder < Base
    attr_accessor :order_id
    attr_accessor :customer_id

    validates :order_id, presence: true
    validates :customer_id, presence: true

    alias :aggregate_id :order_id
  end
end
