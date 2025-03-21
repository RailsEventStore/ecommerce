# frozen_string_literal: true

module Fulfillment
  class OrderRegistered < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :order_number, Infra::Types::OrderNumber
  end
end
