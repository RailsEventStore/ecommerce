require "test_helper"

module ClientOrders
  class UpdateProductAvailabilityTest < InMemoryTestCase
     cover "ClientOrders*"

    def test_reflects_change
      product_id = prepare_product
      other_product_id = prepare_product

      assert_changes("Product.find_by_uid(product_id).available?", from: true, to: false) do
        UpdateProductAvailability.new.call(availability_changed_event(product_id, -1))
      end

      assert_changes("Product.find_by_uid(product_id).available?", from: false, to: true) do
        UpdateProductAvailability.new.call(availability_changed_event(product_id, 10))
      end

      assert_changes("Product.find_by_uid(product_id).available?", from: true, to: false) do
        UpdateProductAvailability.new.call(availability_changed_event(product_id, 0))
      end

      assert Product.find_by_uid(other_product_id).available?
    end

    private

    def prepare_product
      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
          )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "test"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 50))

      product_id
    end

    def supply_product(product_id, quantity)
      run_command(Inventory::Supply.new(product_id: product_id, quantity: quantity))
    end

    def availability_changed_event(product_id, available)
      Inventory::AvailabilityChanged.new(data: { product_id: product_id, available: available })
    end
  end
end
