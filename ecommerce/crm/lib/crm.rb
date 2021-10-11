require "infra"
require_relative "crm/commands"
require_relative "crm/registration"
require_relative "crm/customer_repository"
require_relative "crm/customer"

module Crm
  class Configuration
    def initialize(repository = InMemoryCustomerRepository.new)
      @repository = repository
    end

    def call(cqrs)
      cqrs.register(RegisterCustomer, Registration.new(@repository))
    end
  end
end
