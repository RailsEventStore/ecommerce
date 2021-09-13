require_relative "../../../infra/lib/infra"
require_relative "crm/commands"
require_relative "crm/customer_registration_handler"
require_relative "crm/customer"

module Crm
  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.register(RegisterCustomer, CustomerRegistrationHandler.new)
    end
  end
end
