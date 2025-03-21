require "test_helper"

module ClientOrders
  class ItemRemovedFromBasketTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_remove_item_when_quantity_gt_1
      product_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        ),
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "something"
        ),
        Pricing::SetPrice.new(product_id: product_id, price: 20),
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy"),
      )
      order_id = SecureRandom.uuid
      publish_event(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        ),
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        ),
        Pricing::PriceItemRemoved.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        )
      )

      assert_equal(1, OrderLine.count)
      order_line = OrderLine.find_by(order_uid: order_id)
      assert_equal(order_line.product_id, product_id)
      assert_equal("something", order_line.product_name)
      assert_equal(1, order_line.product_quantity)
    end

    def test_remove_item_when_quantity_eq_1
      product_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        ),
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "Async Remote"
        ),
        Pricing::SetPrice.new(product_id: product_id, price: 20),
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy")
      )
      order_id = SecureRandom.uuid
      publish_event(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        ),
        Pricing::PriceItemRemoved.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        )
      )

      assert_equal(0, OrderLine.count)
    end

    def test_remove_item_when_there_is_another_item
      product_id = SecureRandom.uuid
      another_product_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id
        ),
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "test"
        ),
        Pricing::SetPrice.new(product_id: product_id, price: 20),
        ProductCatalog::RegisterProduct.new(
          product_id: another_product_id
        ),
        ProductCatalog::NameProduct.new(
          product_id: another_product_id,
          name: "test2"
        ),
        Pricing::SetPrice.new(product_id: another_product_id, price: 20),
        Crm::RegisterCustomer.new(customer_id: customer_id, name: "dummy")
      )
      order_id = SecureRandom.uuid
      publish_event(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        ),
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: 20,
            catalog_price: 20,
          }
        ),
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: another_product_id,
            price: 20,
            catalog_price: 20,
          }
        ),
        Pricing::PriceItemRemoved.new(
          data: {
            order_id: order_id,
            product_id: another_product_id,
            price: 20,
            catalog_price: 20,
          }
        )
      )

      assert_equal(1, OrderLine.count,)
      order_lines = OrderLine.where(order_uid: order_id)
      assert_equal(product_id, order_lines[0].product_id)
      assert_equal("test", order_lines[0].product_name)
      assert_equal(2, order_lines[0].product_quantity)
    end
  end
end
