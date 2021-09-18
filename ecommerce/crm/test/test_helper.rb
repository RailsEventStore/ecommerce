require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/crm"

module Crm
  class Test < Infra::InMemoryTest
    attr_reader :customer_repository

    def before_setup
      super
      @customer_repository = InMemoryCustomerRepository.new
      Configuration.new(cqrs, customer_repository).call
    end
  end
end
