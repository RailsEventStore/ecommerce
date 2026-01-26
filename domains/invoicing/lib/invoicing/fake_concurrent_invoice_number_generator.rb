module Invoicing
  class FakeConcurrentInvoiceNumberGenerator
    def initialize
      @counter = 0
    end

    def call(issue_date)
      issue_date.strftime("#{next_number}/%m/%Y")
    end

    private

    def next_number
      @counter += 1
      return 1 if @counter < 2
      @counter - 1
    end
  end
end