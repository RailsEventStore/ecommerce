# frozen_string_literal: true

module Underwriting
  class AcceptOffer
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :application_id

    alias aggregate_id application_id

    def initialize(application_id)
      @application_id = application_id
      valid = UUID.match?(@application_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
