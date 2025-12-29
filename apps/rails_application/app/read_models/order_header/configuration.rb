module OrderHeader
  class Header < ApplicationRecord
    self.table_name = "order_headers"
  end

  private_constant :Header

  class Customer < ApplicationRecord
    self.table_name = "orders_customers"
  end

  private_constant :Customer

  def self.find_by_uid(uid)
    Header.find_by_uid(uid)
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(
        ->(event) { draft_order_header(event) },
        to: [Pricing::OfferDrafted]
      )
      event_store.subscribe(
        ->(event) { assign_customer(event) },
        to: [Crm::CustomerAssignedToOrder]
      )
      event_store.subscribe(
        ->(event) { submit_order(event) },
        to: [Fulfillment::OrderRegistered]
      )
      event_store.subscribe(
        ->(event) { update_state(event, "Paid") },
        to: [Fulfillment::OrderConfirmed]
      )
      event_store.subscribe(
        ->(event) { update_state(event, "Cancelled") },
        to: [Fulfillment::OrderCancelled]
      )
      event_store.subscribe(
        ->(event) { update_state(event, "Expired") },
        to: [Pricing::OfferExpired]
      )
      event_store.subscribe(
        ->(event) { set_shipping_address(event) },
        to: [Shipping::ShippingAddressAddedToShipment]
      )
      event_store.subscribe(
        ->(event) { set_billing_address(event) },
        to: [Invoicing::BillingAddressSet]
      )
      event_store.subscribe(
        ->(event) { issue_invoice(event) },
        to: [Invoicing::InvoiceIssued]
      )
    end

    private

    def find_or_create_header(order_id)
      Header.find_or_create_by!(uid: order_id) { |header| header.state = "Draft" }
    end

    def draft_order_header(event)
      Header.create!(
        uid: event.data.fetch(:order_id),
        state: "Draft"
      )
    end

    def assign_customer(event)
      customer_id = event.data.fetch(:customer_id)
      customer_name = Customer.find_by_uid(customer_id).name
      find_or_create_header(event.data.fetch(:order_id)).update!(customer: customer_name)
    end

    def submit_order(event)
      find_or_create_header(event.data.fetch(:order_id)).update!(
        number: event.data.fetch(:order_number),
        state: "Submitted"
      )
    end

    def update_state(event, state)
      find_or_create_header(event.data.fetch(:order_id)).update!(state: state)
    end

    def set_shipping_address(event)
      find_or_create_header(event.data.fetch(:order_id)).update!(
        shipping_address_present: true
      )
    end

    def set_billing_address(event)
      find_or_create_header(event.data.fetch(:invoice_id)).update!(
        billing_address_present: true
      )
    end

    def issue_invoice(event)
      find_or_create_header(event.data.fetch(:invoice_id)).update!(
        invoice_issued: true,
        invoice_number: event.data.fetch(:invoice_number)
      )
    end
  end
end
