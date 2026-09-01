# frozen_string_literal: true

module Underwriting
  class OfferAccepted < Infra::Event
    attribute :application_id, Infra::Types::UUID
    attribute :premium, Infra::Types::Price
  end
end
