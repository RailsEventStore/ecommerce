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

    def put_in_force
      raise InvalidState unless @state.equal?(:issued)
      apply PolicyInForce.new(data: { policy_id: @id })
    end

    def terminate
      raise InvalidState unless @state.equal?(:in_force)
      apply PolicyTerminated.new(data: { policy_id: @id })
    end

    on PolicyIssued do |event|
      @state = :issued
    end

    on PolicyInForce do |event|
      @state = :in_force
    end

    on PolicyTerminated do |event|
      @state = :terminated
    end
  end
end
