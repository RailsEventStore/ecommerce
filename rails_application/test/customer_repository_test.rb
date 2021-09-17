require "test_helper"
require_relative "../../ecommerce/crm/lib/crm/customer_repository_examples"

class CustomerRepositoryTest < ActiveSupport::TestCase
  include Crm::CustomerRepositoryExamples

  attr_reader :repository

  def setup
    super
    @repository = CustomerRepository.new
    CustomerRepository::Record.delete_all
  end
end
