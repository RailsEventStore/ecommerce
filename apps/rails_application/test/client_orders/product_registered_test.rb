require "test_helper"

module ClientOrders
  class ProductRegisteredTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, command_bus)
      ClientOrders::Configuration.new.call(event_store)
      Ecommerce::Configuration.new(
        number_generator: Rails.configuration.number_generator,
        payment_gateway: Rails.configuration.payment_gateway
      ).call(event_store, command_bus)
    end

    def test_reflects_change
      product_id = SecureRandom.uuid

      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))

      assert_equal(product_id, Product.find_by_uid(product_id).uid)
    end

  end
end
