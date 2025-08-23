module Processes
  class InvoiceItemValueCalculated < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :quantity, Infra::Types::Quantity
    attribute :discounted_amount, Infra::Types::Value
    attribute :amount, Infra::Types::Value
  end
end
