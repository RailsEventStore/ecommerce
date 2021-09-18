require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/crm"

module Crm
  class Test < Infra::InMemoryTest
    attr_reader :customer_repository

    def before_setup
      super
      @customer_repository = InMemoryCustomerRepository.new
      Configuration.new(customer_repository).call(event_store, command_bus)
    end
  end
end
