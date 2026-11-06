require "test_helper"

module Orders
  class SubmitServiceTest < InMemoryTestCase
    cover Orders::SubmitService
    cover "Orders::SubmitService#submit_order"

    def configure(event_store, command_bus)
      Orders::Configuration.new.call(event_store)
      ClientOrders::Configuration.new.call(event_store)
      Products::Configuration.new(event_store).call
      Ecommerce::Configuration.new(
        number_generator: Rails.configuration.number_generator,
        payment_gateway: Rails.configuration.payment_gateway
      ).call(event_store, command_bus)
      Processes::Configuration.new.call(event_store, command_bus)
    end

    def test_successful_order_submission
      prepare_order
      add_item

      assert_instance_of(Fulfillment::OrderRegistered, submit_order)

      assert_equal("Submitted", ClientOrders.find_order(order_id).state)
      assert_equal(customer_id, ClientOrders.find_order(order_id).client_uid)
    end

    def test_order_submission_with_unavailable_products
      prepare_order
      run_command(Inventory::Supply.new(product_id, 1))
      run_command(Inventory::Reserve.new(product_id, 1))
      add_item
      prepare_product(another_product_id, "Fearless Refactoring", 49)
      run_command(Pricing::AddPriceItem.new(order_id, another_product_id, 49))

      assert_equal(
        Pricing::OfferRejected.new(data: {
          order_id: order_id,
          reason: "Some products were unavailable",
          unavailable_product_ids: [product_id]
        }).data,
        submit_order.data
      )
      assert_instance_of(Pricing::OfferRejected, event_store.read.stream("Pricing::Offer$#{order_id}").last)
      assert_equal(customer_id, ClientOrders.find_order(order_id).client_uid)
    end

    def test_empty_order_rejection_is_recorded_without_assigning_a_customer
      prepare_order

      assert_instance_of(Pricing::EmptyOrderAcceptanceRejected, submit_order)
      assert_equal(
        [Pricing::OrderAcceptanceRequested, Pricing::EmptyOrderAcceptanceRejected],
        event_store.read.stream("Pricing::OrderAcceptance$#{order_id}").map(&:class)
      )
      assert_equal("Draft", ClientOrders.find_order(order_id).state)
      assert_nil(ClientOrders.find_order(order_id).client_uid)

      add_item

      assert_instance_of(Fulfillment::OrderRegistered, submit_order)
      assert_equal(customer_id, ClientOrders.find_order(order_id).client_uid)
    end

    def test_result_ignores_rejections_of_other_orders_during_submission
      prepare_order
      add_item
      event_store.subscribe(
        ->(_event) { run_command(Pricing::RejectEmptyOrderAcceptance.new(another_order_id)) },
        to: [Pricing::OfferAccepted]
      )

      assert_instance_of(Fulfillment::OrderRegistered, submit_order)
      assert_equal(customer_id, ClientOrders.find_order(order_id).client_uid)
    end

    private

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def another_order_id
      @another_order_id ||= SecureRandom.uuid
    end

    def customer_id
      @customer_id ||= SecureRandom.uuid
    end

    def product_id
      @product_id ||= SecureRandom.uuid
    end

    def another_product_id
      @another_product_id ||= SecureRandom.uuid
    end

    def prepare_order
      run_command(Crm::RegisterCustomer.new(customer_id, "John Doe"))
      prepare_product(product_id, "Async Remote", 49)
      run_command(Pricing::DraftOffer.new(order_id))
    end

    def add_item
      run_command(Pricing::AddPriceItem.new(order_id, product_id, 49))
    end

    def submit_order
      Orders::SubmitService.new(order_id, customer_id).call
    end

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product(product_id, name, price)
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      run_command(
        ProductCatalog::RegisterProduct.new(product_id)
      )
      run_command(
        ProductCatalog::NameProduct.new(product_id, name)
      )
      run_command(Pricing::SetPrice.new(product_id, price))
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: vat_rate }))
    end
  end
end
