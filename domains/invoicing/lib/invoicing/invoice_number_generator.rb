module Invoicing
  class InvoiceNumberGenerator
    def initialize(event_store)
      @event_store = event_store
    end

    def call(issue_date)
      issue_date.strftime("#{next_number(issue_date)}/%m/%Y")
    end

    private

    def next_number(issue_date)
      stream_name = "InvoiceIssued$#{issue_date.strftime("%Y-%m")}"
      @event_store.read.stream(stream_name).count + 1
    end
  end
end