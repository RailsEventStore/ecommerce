require "test_helper"

module ClientOrders
  class SubmitButtonTest < InMemoryTestCase
    cover "ClientOrders::Rendering::SubmitButton*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_renders_submit_button_only_for_orders_with_projected_items
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "Free sample" }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 0 }))
      [order_id, another_order_id].each do |id|
        event_store.publish(Pricing::OfferDrafted.new(data: { order_id: id }))
        event_store.publish(Pricing::PriceItemAdded.new(data: { order_id: id, product_id: product_id, price: 0 }))
      end

      assert(Rendering::SubmitButton.call(order_id).html_safe?)
      assert_equal("Create Order", Nokogiri::HTML5.fragment(Rendering::SubmitButton.call(order_id)).css("div.mt-8 > input[type='submit'].bg-blue-500.text-white").sole["value"])

      event_store.publish(Pricing::PriceItemRemoved.new(data: { order_id: order_id, product_id: product_id, price: 0 }))
      event_store.define_singleton_method(:read) { raise "Rendering must use projected state" }

      assert_equal("", Rendering::SubmitButton.call(order_id))
      assert_equal("Create Order", Nokogiri::HTML5.fragment(Rendering::SubmitButton.call(another_order_id)).css("input[type='submit']").sole["value"])
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def another_order_id
      @another_order_id ||= SecureRandom.uuid
    end

    def product_id
      @product_id ||= SecureRandom.uuid
    end
  end
end
