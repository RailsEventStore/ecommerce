require_relative "../../../infra/lib/infra"
require_relative "crm/commands"
require_relative "crm/registration"
require_relative "crm/customer_repository"
require_relative "crm/customer"

module Crm
  class Configuration
    def initialize(repository = InMemoryCustomerRepository.new)
      @repository = repository
    end

    def call(event_store, command_bus)
      cqrs = Infra::Cqrs.new(event_store, command_bus)
      cqrs.register(RegisterCustomer, Registration.new(@repository))
    end
  end
end
