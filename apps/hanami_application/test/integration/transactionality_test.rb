# frozen_string_literal: true

require "test_helper"
require "securerandom"

class TransactionalityTest < Hanami::Minitest::Test
  test "a failing subscriber rolls back the event and the read model projection" do
    event_store = Hanami.app["event_store"]
    command_bus = Hanami.app["command_bus"]
    products = Hanami.app["relations.products"]
    product_id = SecureRandom.uuid

    unsubscribe = event_store.subscribe(->(_event) { raise "boom" }, to: [ProductCatalog::ProductRegistered])
    begin
      assert_raises(RuntimeError) do
        command_bus.call(ProductCatalog::RegisterProduct.new(product_id: product_id))
      end
    ensure
      unsubscribe.call
    end

    assert_nil products.by_pk(product_id).one
    registered = event_store.read.of_type([ProductCatalog::ProductRegistered]).to_a
    assert_empty registered.select { |event| event.data.fetch(:product_id) == product_id }
  end
end
