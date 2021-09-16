require_relative "test_helper"

module Crm
  class InMemoryCustomerRepositoryTest < Test
    include CustomerRepositoryExamples

    cover "Crm::InMemoryCustomerRepository*"

    attr_reader :repository

    def setup
      super
      @repository = InMemoryCustomerRepository.new
    end
  end
end

