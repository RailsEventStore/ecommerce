# frozen_string_literal: true

module Policies
  class Policy
    include AggregateRoot

    InvalidState = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def issue(premium)
      raise InvalidState if @state
      apply PolicyIssued.new(data: { policy_id: @id, premium: premium })
    end

    def activate
      raise InvalidState unless @state.equal?(:issued)
      apply PolicyActivated.new(data: { policy_id: @id })
    end

    def terminate
      raise InvalidState unless @state.equal?(:active)
      apply PolicyTerminated.new(data: { policy_id: @id })
    end

    on PolicyIssued do |event|
      @state = :issued
    end

    on PolicyActivated do |event|
      @state = :active
    end

    on PolicyTerminated do |event|
      @state = :terminated
    end
  end
end
