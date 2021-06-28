module Crm
  class Customer < ApplicationRecord
    AlreadyRegistered = Class.new(StandardError)

    def register(name)
      raise AlreadyRegistered unless new_record?
      self.name = name
    end
  end

  class RegisterCustomer < Command
    attribute :customer_id, Types::UUID
    attribute :name, Types::String
  end

  class CustomerRegistrationHandler
    def call(cmd)
      customer = Customer.find_or_initialize_by(id: cmd.customer_id)
      customer.register(cmd.name)
      customer.save!
    end
  end
end
