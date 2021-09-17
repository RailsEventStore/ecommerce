require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/crm"
require_relative "../lib/crm/customer_repository_examples"

module Crm
  class Test < Infra::InMemoryTest
    def before_setup
      super
      @customer_repository = InMemoryCustomerRepository.new
      Configuration.new(cqrs, @customer_repository).call
    end

    attr_reader :customer_repository
  end
end
