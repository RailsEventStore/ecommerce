# frozen_string_literal: true

module Fulfillment
  class OrderArchived < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end