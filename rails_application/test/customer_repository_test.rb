require "test_helper"
require_relative "../../ecommerce/crm/lib/crm/customer_repository_examples"

class CustomerRepositoryTest < ActiveSupport::TestCase
  include Crm::CustomerRepositoryExamples.for(-> { CustomerRepository.new })

  def setup
    super
    CustomerRepository::Record.delete_all
  end
end
