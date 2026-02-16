require "test_helper"

module OrderHeader
  class OrderHeaderTest < InMemoryTestCase
    cover "OrderHeader*"

    def configure(event_store, _command_bus)
      OrderHeader::Configuration.new.call(event_store)
    end

    def test_header_is_created_when_offer_drafted
      order_id = SecureRandom.uuid

      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal("Draft", header.state)
    end

    def test_draft_orders_returns_only_draft_orders_in_store
      store_id = SecureRandom.uuid
      other_store_id = SecureRandom.uuid
      draft_order_1 = SecureRandom.uuid
      draft_order_2 = SecureRandom.uuid
      submitted_order = SecureRandom.uuid
      other_store_order = SecureRandom.uuid

      draft_order_in_store(draft_order_1, store_id)
      draft_order_in_store(draft_order_2, store_id)
      draft_order_in_store(submitted_order, store_id)
      draft_order_in_store(other_store_order, other_store_id)
      event_store.publish(Fulfillment::OrderRegistered.new(data: { order_id: submitted_order, order_number: "2024/12/001" }))

      draft_orders = OrderHeader.draft_orders(store_id)
      draft_order_uids = draft_orders.map(&:uid)

      assert_equal(2, draft_orders.count)
      assert_includes(draft_order_uids, draft_order_1)
      assert_includes(draft_order_uids, draft_order_2)
      refute_includes(draft_order_uids, submitted_order)
      refute_includes(draft_order_uids, other_store_order)
    end

    def test_assigns_store_to_header
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid
      other_order_id = SecureRandom.uuid

      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: other_order_id }))
      event_store.publish(Stores::OfferRegistered.new(data: { order_id: order_id, store_id: store_id }))

      assert_equal(store_id, OrderHeader.find_by_uid(order_id).store_id)
      assert_nil(OrderHeader.find_by_uid(other_order_id).store_id)
    end

    def test_assigns_customer_to_header
      order_id = SecureRandom.uuid
      customer_id = create_customer("John Doe")

      event_store.publish(Crm::CustomerAssignedToOrder.new(data: { order_id: order_id, customer_id: customer_id }))

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal("John Doe", header.customer)
    end

    def test_creates_header_with_draft_state_when_not_exists
      order_id = SecureRandom.uuid
      customer_id = create_customer("Jane Doe")

      event_store.publish(Crm::CustomerAssignedToOrder.new(data: { order_id: order_id, customer_id: customer_id }))

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal("Draft", header.state)
      assert_equal("Jane Doe", header.customer)
    end

    def test_submits_order_with_number_and_state
      order_id = SecureRandom.uuid
      order_number = "2024/12/001"

      event_store.publish(Fulfillment::OrderRegistered.new(data: { order_id: order_id, order_number: order_number }))

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal(order_number, header.number)
      assert_equal("Submitted", header.state)
    end

    def test_confirms_order_with_paid_state
      order_id = SecureRandom.uuid
      setup_order_with_items(order_id)

      event_store.publish(Fulfillment::OrderConfirmed.new(data: { order_id: order_id }))

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal("Paid", header.state)
    end

    def test_cancels_order_with_cancelled_state
      order_id = SecureRandom.uuid
      setup_order_with_items(order_id)

      event_store.publish(Fulfillment::OrderCancelled.new(data: { order_id: order_id }))

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal("Cancelled", header.state)
    end

    def test_expires_order_with_expired_state
      order_id = SecureRandom.uuid
      setup_order_with_items(order_id)

      event_store.publish(Pricing::OfferExpired.new(data: { order_id: order_id }))

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal("Expired", header.state)
    end

    def test_sets_shipping_address_present
      order_id = SecureRandom.uuid

      event_store.publish(
        Shipping::ShippingAddressAddedToShipment.new(
          data: {
            order_id: order_id,
            postal_address: {
              line_1: "123 Main St",
              line_2: "Apt 4",
              line_3: "City",
              line_4: "Country"
            }
          }
        )
      )

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal(true, header.shipping_address_present)
    end

    def test_sets_billing_address_present
      order_id = SecureRandom.uuid

      event_store.publish(
        Invoicing::BillingAddressSet.new(
          data: {
            invoice_id: order_id,
            tax_id_number: "123456",
            postal_address: {
              line_1: "Street 1",
              line_2: "City",
              line_3: "State",
              line_4: "Country"
            }
          }
        )
      )

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal(true, header.billing_address_present)
    end

    def test_marks_invoice_as_issued_with_number
      order_id = SecureRandom.uuid
      issue_date = Date.today
      invoice_number = Invoicing::InvoiceNumberGenerator.new(event_store).call(issue_date)

      event_store.publish(
        Invoicing::InvoiceIssued.new(
          data: {
            invoice_id: order_id,
            issue_date: issue_date,
            disposal_date: issue_date + 30,
            invoice_number: invoice_number
          }
        )
      )

      header = OrderHeader.find_by_uid(order_id)
      assert(header)
      assert_equal(true, header.invoice_issued)
      assert_equal(invoice_number, header.invoice_number)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def draft_order_in_store(order_id, store_id)
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))
      event_store.publish(Stores::OfferRegistered.new(data: { order_id: order_id, store_id: store_id }))
    end

    def create_customer(name)
      customer_id = SecureRandom.uuid
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: name }))
      customer_id
    end

    def create_product(product_id, name, price)
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: name }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: vat_rate }))
    end

    def setup_order_with_items(order_id)
      customer_id = create_customer("John Doe")
      product_id = SecureRandom.uuid

      create_product(product_id, "Test Product", 100)
      event_store.publish(Pricing::PriceItemAdded.new(data: { order_id: order_id, product_id: product_id, base_price: 100, price: 100, base_total_value: 100, total_value: 100 }))
      event_store.publish(Pricing::OfferAccepted.new(data: { order_id: order_id, order_lines: [{ product_id: product_id, quantity: 1 }] }))
      event_store.publish(Crm::CustomerAssignedToOrder.new(data: { customer_id: customer_id, order_id: order_id }))
      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: order_id, discounted_amount: 0, total_amount: 100, items: [{ product_id: product_id, quantity: 1, amount: 100 }] }))
    end
  end
end
