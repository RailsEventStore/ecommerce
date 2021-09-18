require_relative "test_helper"
require_relative "../lib/crm/customer_repository_examples"

module Crm
  class InMemoryCustomerRepositoryTest < Test
    cover "Crm::InMemoryCustomerRepository*"

    include CustomerRepositoryExamples.for(
              -> { InMemoryCustomerRepository.new }
            )
  end
end
