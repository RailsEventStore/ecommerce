require_relative "test_helper"

module Crm
  class InMemoryCustomerRepositoryTest < Test
    include CustomerRepositoryExamples.for(-> { InMemoryCustomerRepository.new })

    cover "Crm::InMemoryCustomerRepository*"
  end
end
