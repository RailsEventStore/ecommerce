require_relative "../../../infra/lib/infra"
require_relative "crm/commands"
require_relative "crm/registration"
require_relative "crm/customer_repository"
require_relative "crm/customer"

module Crm
  class Configuration
    def initialize(cqrs, repository)
      @cqrs = cqrs
      @repository = repository
    end

    def call
      @cqrs.register(RegisterCustomer, Registration.new(@repository))
    end
  end
end
