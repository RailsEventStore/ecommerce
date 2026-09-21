module Ordering
  class CreateDraftRefund
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :refund_id, :order_id

    alias aggregate_id refund_id

    def initialize(refund_id, order_id)
      @refund_id = refund_id
      @order_id = order_id
      valid = UUID.match?(@refund_id) && UUID.match?(@order_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
