require "test_helper"

module Processes
  class InvoiceGenerationTest < ProcessTest
    cover "Processes::InvoiceGeneration"

    def test_calculates_sub_amounts
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 20, 20)
      event_2 = price_item_added(product_2_id, 30, 30)
      event_3 = price_item_added(product_2_id, 30, 30)

      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)

      process.call(event_1)
      process.call(event_2)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 20
          }
        ),
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_2_id,
            quantity: 2,
            amount: 60,
            discounted_amount: 60
          }
        )
      ) { process.call(event_3) }
    end

    def test_calculates_sub_amounts_with_discount
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 20, 20)
      event_2 = price_item_added(product_2_id, 30, 30)
      event_3 = price_item_added(product_2_id, 30, 30)
      discount_event = percentage_discount_set("general_discount", 10)

      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      event_store.append(discount_event)

      process.call(event_1)
      process.call(event_2)
      process.call(event_3)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 18
          }
        ),
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_2_id,
            quantity: 2,
            amount: 60,
            discounted_amount: 54
          }
        )
      ) { process.call(discount_event) }
    end

    def test_calculates_sub_amounts_with_100_percent_discount
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 20, 20)
      discount_event = percentage_discount_set("general_discount", 100)

      event_store.append(event_1)
      event_store.append(discount_event)

      process.call(event_1)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 0
          }
        )
      ) { process.call(discount_event) }
    end

    def test_calculates_sub_amounts_with_multiple_discounts
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 100, 100)
      discount_1 = percentage_discount_set("general_discount", 10)
      discount_2 = percentage_discount_set("time_promotion", 15)

      event_store.append(event_1)
      event_store.append(discount_1)
      event_store.append(discount_2)

      process.call(event_1)
      process.call(discount_1)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 100,
            discounted_amount: 75
          }
        )
      ) { process.call(discount_2) }
    end

    def test_calculates_sub_amounts_after_item_removal
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 20, 20)
      event_2 = price_item_added(product_2_id, 30, 30)
      event_3 = price_item_added(product_2_id, 30, 30)
      remove_event = price_item_removed(product_2_id, 30)

      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      event_store.append(remove_event)

      process.call(event_1)
      process.call(event_2)
      process.call(event_3)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 20
          }
        ),
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_2_id,
            quantity: 1,
            amount: 30,
            discounted_amount: 30
          }
        )
      ) { process.call(remove_event) }
    end

    def test_calculates_sub_amounts_with_discount_changed
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 100, 100)
      discount_set = percentage_discount_set("general_discount", 10)
      discount_changed = percentage_discount_changed("general_discount", 20)

      event_store.append(event_1)
      event_store.append(discount_set)
      event_store.append(discount_changed)

      process.call(event_1)
      process.call(discount_set)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 100,
            discounted_amount: 80
          }
        )
      ) { process.call(discount_changed) }
    end

    def test_calculates_sub_amounts_with_discount_removed
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 100, 100)
      discount_set = percentage_discount_set("general_discount", 10)
      discount_removed = percentage_discount_removed("general_discount")

      event_store.append(event_1)
      event_store.append(discount_set)
      event_store.append(discount_removed)

      process.call(event_1)
      process.call(discount_set)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 100,
            discounted_amount: 100
          }
        )
      ) { process.call(discount_removed) }
    end

    def test_calculates_sub_amounts_with_over_100_percent_discount
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 100, 100)
      discount_1 = percentage_discount_set("general_discount", 60)
      discount_2 = percentage_discount_set("time_promotion", 50)

      event_store.append(event_1)
      event_store.append(discount_1)
      event_store.append(discount_2)

      process.call(event_1)
      process.call(discount_1)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 100,
            discounted_amount: 0
          }
        )
      ) { process.call(discount_2) }
    end

    def test_calculates_sub_amounts_with_discount_type_replacement
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 100, 100)
      discount_1 = percentage_discount_set("general_discount", 10)
      discount_2 = percentage_discount_set("time_promotion", 20)
      discount_changed = percentage_discount_changed("general_discount", 30)

      event_store.append(event_1)
      event_store.append(discount_1)
      event_store.append(discount_2)
      event_store.append(discount_changed)

      process.call(event_1)
      process.call(discount_1)
      process.call(discount_2)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 100,
            discounted_amount: 50
          }
        )
      ) { process.call(discount_changed) }
    end

    def test_discount_removal_preserves_other_discounts
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 100, 100)
      discount_1 = percentage_discount_set("general_discount", 10)
      discount_2 = percentage_discount_set("time_promotion", 20)
      discount_removed = percentage_discount_removed("general_discount")

      event_store.append(event_1)
      event_store.append(discount_1)
      event_store.append(discount_2)
      event_store.append(discount_removed)

      process.call(event_1)
      process.call(discount_1)
      process.call(discount_2)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 100,
            discounted_amount: 80
          }
        )
      ) { process.call(discount_removed) }
    end

    def test_discount_set_replaces_existing_discount_type
      process = InvoiceGeneration.new(event_store, command_bus)
      product_1_id = SecureRandom.uuid
      stream = "Processes::InvoiceGeneration$#{order_id}"

      event_1 = price_item_added(product_1_id, 100, 100)
      discount_1 = percentage_discount_set("general_discount", 10)
      discount_2 = percentage_discount_set("general_discount", 25)

      event_store.append(event_1)
      event_store.append(discount_1)
      event_store.append(discount_2)

      process.call(event_1)
      process.call(discount_1)

      assert_events_contain(
        stream,
        Processes::InvoiceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_1_id,
            quantity: 1,
            amount: 100,
            discounted_amount: 75
          }
        )
      ) { process.call(discount_2) }
    end

    private

    def price_item_added(product_id = SecureRandom.uuid, base_price = 100, price = 100)
      Pricing::PriceItemAdded.new(data: {
        order_id: order_id,
        product_id: product_id,
        base_price: base_price,
        price: price
      })
    end

    def price_item_removed(product_id, price)
      Pricing::PriceItemRemoved.new(data: {
        order_id: order_id,
        product_id: product_id,
        base_price: price,
        price: price
      })
    end

    def percentage_discount_set(type, amount)
      Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: type,
        amount: amount
      })
    end

    def percentage_discount_changed(type, amount)
      Pricing::PercentageDiscountChanged.new(data: {
        order_id: order_id,
        type: type,
        amount: amount
      })
    end

    def percentage_discount_removed(type)
      Pricing::PercentageDiscountRemoved.new(data: {
        order_id: order_id,
        type: type
      })
    end

  end
end
