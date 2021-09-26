require "test_helper"
require_relative "../../ecommerce/crm/lib/crm/customer_repository_examples"

class CustomerRepositoryTest < ActiveSupport::TestCase
  include Crm::CustomerRepositoryExamples.for(-> { Ecommerce::CustomerRepository.new })

  def setup
    super
    Ecommerce::CustomerRepository::Record.delete_all
  end
end
