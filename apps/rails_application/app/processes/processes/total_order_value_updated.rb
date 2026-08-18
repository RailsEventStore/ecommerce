module Processes
  class TotalOrderValueUpdated < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :total_amount, Infra::Types::Price
    attribute :discounted_amount, Infra::Types::Price
    attribute? :free_product_id, Infra::Types::UUID
    attribute? :free_product_saving, Infra::Types::Price
    attribute? :items, Infra::Types::Array do
      attribute :product_id, Infra::Types::UUID
      attribute :quantity, Infra::Types::Quantity
      attribute :amount, Infra::Types::Price
    end
  end
end
