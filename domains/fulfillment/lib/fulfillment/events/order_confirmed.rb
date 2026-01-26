# frozen_string_literal: true

module Fulfillment
  class OrderConfirmed < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
