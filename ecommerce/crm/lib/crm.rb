require "infra"
require_relative "crm/commands"
require_relative "crm/registration"

module Crm
  AlreadyRegistered = Class.new(StandardError)

  class CustomerRegistered < Infra::Event
    attribute :customer_id, Infra::Types::UUID
    attribute :name,       Infra::Types::String
  end

  class Configuration

    def call(cqrs)
      cqrs.register(RegisterCustomer, Registration.new(cqrs))
    end
  end
end
