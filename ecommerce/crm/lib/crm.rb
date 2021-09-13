require_relative "../../../infra/lib/infra"

module Crm
  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.register(RegisterCustomer, CustomerRegistrationHandler.new)
    end
  end
  class Customer < ApplicationRecord
    AlreadyRegistered = Class.new(StandardError)

    def register(name)
      raise AlreadyRegistered unless new_record?
      self.name = name
    end
  end

  class RegisterCustomer < Infra::Command
    attribute :customer_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end

  class CustomerRegistrationHandler
    def call(cmd)
      customer = Customer.find_or_initialize_by(id: cmd.customer_id)
      customer.register(cmd.name)
      customer.save!
    end
  end
end
