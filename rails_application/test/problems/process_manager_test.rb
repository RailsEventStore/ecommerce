# frozen_string_literal: true

require "test_helper"

class ProcessManagerTest < InMemoryTestCase
  def test_schedules_email_sending_only_when_process_is_finished
    event_store = Rails.configuration.event_store
    email_client = Rails.configuration.email_client
    Rails.configuration.email_client = FakeEmailClient.new

    event_store.publish(Ordering::OrderPaid.new(data: { id: "111" }))
    event_store.publish(Invoicing::InvoiceGenerated.new(data: { order_id: "111" }))

    assert_equal ["111"], Rails.configuration.email_client.sent_emails
  ensure
    Rails.configuration.email_client = email_client
  end

  class FakeEmailClient
    def initialize
      @sent_emails = []
    end

    def send_email(order_id)
      @sent_emails << order_id
    end

    def sent_emails
      @sent_emails
    end
  end
end