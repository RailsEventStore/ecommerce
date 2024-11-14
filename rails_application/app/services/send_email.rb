# frozen_string_literal: true

class SendEmail
  def call(event)
    event_store.link(event.event_id, stream_name: "Sales$#{order_id(event)}")

    state = {}

    event_store.read.stream("Sales$#{order_id(event)}").each do |event_in_stream|
      case event_in_stream
      when Ordering::OrderPaid
        state[:order_paid] = true
      when Invoicing::InvoiceGenerated
        state[:invoice_generated] = true
      end
    end

    if state[:order_paid] && state[:invoice_generated]
      Rails.configuration.email_client.send_email(order_id(event))
    end
  end

  private

  def order_id(event)
    case event
    when Ordering::OrderPaid
      event.data[:id]
    when Invoicing::InvoiceGenerated
      event.data[:order_id]
    end
  end

  def event_store
    Rails.configuration.event_store
  end
end
