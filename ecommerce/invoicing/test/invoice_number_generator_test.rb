require_relative "test_helper"

module Invoicing
  class InvoiceNumberGeneratorTest < Test
    cover "Invoicing::InvoiceNumberGenerator"

    def test_fetching_next_number
      issue_date = Date.new(2022, 1, 5)
      number_generator = InvoiceNumberGenerator.new(event_store)
      assert_equal("1/01/2022", number_generator.call(issue_date))
      issue_random_invoice(issue_date)
      assert_equal("2/01/2022", number_generator.call(issue_date))
      next_month_issue_date = Date.new(2022, 2, 5)
      assert_equal("1/02/2022", number_generator.call(next_month_issue_date))
      next_year_issue_date = Date.new(2023, 1, 5)
      assert_equal("1/01/2023", number_generator.call(next_year_issue_date))
    end

    private

    def issue_random_invoice(issue_date)
      invoice_id = SecureRandom.uuid
      set_billing_address(invoice_id)
      run_command(IssueInvoice.new(invoice_id: invoice_id, issue_date: issue_date))
    end
  end
end