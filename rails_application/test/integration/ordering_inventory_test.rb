require "test_helper"

class OrderingInventoryTest < Ecommerce::RealRESIntegrationTestCase
  include Infra::TestPlumbing.with(
    event_store: ->{ Rails.configuration.event_store },
    command_bus: ->{ Rails.configuration.command_bus }
  )

  cover "Ordering::OnSubmitOrder*"

  def test_inventory_error_prevents_order_submission
    aggregate_id = SecureRandom.uuid
    customer_id = SecureRandom.uuid
    product_id = SecureRandom.uuid

    arrange(
      Crm::RegisterCustomer.new(customer_id: customer_id, name: "test"),
      ProductCatalog::RegisterProduct.new(product_id: product_id, name: "Async Remote"),
      Pricing::SetPrice.new(product_id: product_id, price: 39),
      Inventory::Supply.new(product_id: product_id, quantity: 1),
      Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id),
      Pricing::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id)
    )
    stream = "Ordering::Order$#{aggregate_id}"
    assert_events(stream) do
      assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
        act(
          Ordering::SubmitOrder.new(order_id: aggregate_id, customer_id: customer_id)
        )
      end
    end
  end
end