require "test_helper"

module Deals
  class DealsTest < InMemoryTestCase
    cover "Deals*"

    def configure(event_store, _command_bus)
      Deals::Configuration.new.call(event_store)
    end

    def test_deal_drafted
      draft_deal(order_id)
      draft_deal(other_order_id)

      assert_equal(2, Deals.deals_for_store(store_id).count)
    end

    def test_deal_has_customer_name
      register_customer(customer_id, "John Doe")
      draft_deal(order_id)
      assign_customer(customer_id, order_id)

      assert_equal("John Doe", deal_for(order_id).customer_name)
    end

    def test_deal_has_updated_customer_name
      other_customer_id = SecureRandom.uuid
      register_customer(customer_id, "John Doe")
      register_customer(other_customer_id, "Jane Smith")
      draft_deal(order_id)
      assign_customer(customer_id, order_id)
      assign_customer(other_customer_id, order_id)

      assert_equal("Jane Smith", deal_for(order_id).customer_name)
    end

    def test_deal_has_value
      draft_deal(order_id)
      draft_deal(other_order_id)
      update_value(order_id, 99.99)

      assert_equal(BigDecimal("99.99"), deal_for(order_id).value)
      assert_nil(deal_for(other_order_id).value)
    end

    def test_deal_value_updates
      draft_deal(order_id)
      update_value(order_id, 99.99)
      update_value(order_id, 149.99)

      assert_equal(BigDecimal("149.99"), deal_for(order_id).value)
    end

    def test_deal_submitted
      draft_deal(order_id)
      draft_deal(other_order_id)
      submit_deal(order_id, "2024/01/123")

      assert_equal("Pending Payment", deal_for(order_id).stage)
      assert_equal("2024/01/123", deal_for(order_id).order_number)
      assert_equal("Draft", deal_for(other_order_id).stage)
    end

    def test_deal_won
      draft_deal(order_id)
      draft_deal(other_order_id)
      setup_order_with_items(order_id)
      event_store.publish(Fulfillment::OrderConfirmed.new(data: { order_id: order_id }))

      assert_equal("Won", deal_for(order_id).stage)
      assert_equal("Draft", deal_for(other_order_id).stage)
    end

    def test_deal_lost_on_cancel
      draft_deal(order_id)
      draft_deal(other_order_id)
      setup_order_with_items(order_id)
      event_store.publish(Fulfillment::OrderCancelled.new(data: { order_id: order_id }))

      assert_equal("Lost", deal_for(order_id).stage)
      assert_equal("Draft", deal_for(other_order_id).stage)
    end

    def test_deal_lost_on_expire
      draft_deal(order_id)
      draft_deal(other_order_id)
      setup_order_with_items(order_id)
      event_store.publish(Pricing::OfferExpired.new(data: { order_id: order_id }))

      assert_equal("Lost", deal_for(order_id).stage)
      assert_equal("Draft", deal_for(other_order_id).stage)
    end

    def test_deals_filtered_by_store
      other_store_id = SecureRandom.uuid
      draft_deal(order_id)
      draft_deal(other_order_id, other_store_id)

      assert_equal(1, Deals.deals_for_store(store_id).count)
      assert_equal(1, Deals.deals_for_store(other_store_id).count)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def other_order_id
      @other_order_id ||= SecureRandom.uuid
    end

    def customer_id
      @customer_id ||= SecureRandom.uuid
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end

    def draft_deal(oid, sid = store_id)
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: oid }))
      event_store.publish(Stores::OfferRegistered.new(data: { order_id: oid, store_id: sid }))
    end

    def register_customer(cid, name)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: cid, name: name }))
    end

    def assign_customer(cid, oid)
      event_store.publish(Crm::CustomerAssignedToOrder.new(data: { customer_id: cid, order_id: oid }))
    end

    def update_value(oid, amount)
      event_store.publish(Processes::TotalOrderValueUpdated.new(data: { order_id: oid, discounted_amount: amount, total_amount: amount, items: [] }))
    end

    def submit_deal(oid, order_number)
      event_store.publish(Fulfillment::OrderRegistered.new(data: { order_id: oid, order_number: order_number }))
    end

    def deal_for(oid)
      Deals.deals_for_store(store_id).find_by!(uid: oid)
    end

    def setup_order_with_items(oid)
      cid = SecureRandom.uuid
      product_id = SecureRandom.uuid

      register_customer(cid, "John Doe")
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "Test Product" }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 100 }))
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: Infra::Types::VatRate.new(rate: 20, code: "20") }))
      event_store.publish(Pricing::PriceItemAdded.new(data: { order_id: oid, product_id: product_id, base_price: 100, price: 100, base_total_value: 100, total_value: 100 }))
      event_store.publish(Pricing::OfferAccepted.new(data: { order_id: oid, order_lines: [{ product_id: product_id, quantity: 1 }] }))
      assign_customer(cid, oid)
      update_value(oid, 100)
    end
  end
end
