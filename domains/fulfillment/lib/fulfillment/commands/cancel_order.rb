# frozen_string_literal: true

module Fulfillment
  class CancelOrder < Infra::Command
    attribute :order_id, Infra::Types::UUID

    alias aggregate_id order_id
  end
end
