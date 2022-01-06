require_relative "test_helper"

module Invoicing
  class FakeConcurrentInvoiceNumberGeneratorTest < Test
    cover "Invoicing::FakeInvoiceNumberGenerator"

    def test_fetching_next_number
      issue_date = Date.new(2022, 1, 5)
      number_generator = FakeConcurrentInvoiceNumberGenerator.new
      assert_equal("1/01/2022", number_generator.call(issue_date))
      assert_equal("1/01/2022", number_generator.call(issue_date))
      assert_equal("2/01/2022", number_generator.call(issue_date))
    end
  end
end