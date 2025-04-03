require "test_helper"

module Orders
  class RemoveTimePromotionDiscountTest < InMemoryTestCase
    cover "Orders*"

    def test_removes_time_promotion_discount_value
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      create_active_time_promotion
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)

      travel_to(1.minute.from_now) do
        item_added_to_basket(order_id, product_id)
        order = Orders::Order.find_by(uid: order_id)
        assert_nil order.time_promotion_discount_value
      end
    end

    def test_does_not_removes_time_promotion_when_removing_general_discount
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      create_active_time_promotion
      customer_registered(customer_id)
      prepare_product(product_id)
      item_added_to_basket(order_id, product_id)
      set_percentage_discount(order_id)

      assert_no_changes -> { Orders::Order.find_by(uid: order_id).time_promotion_discount_value } do
        remove_percentage_discount(order_id)
      end
    end

    private

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Pricing::PriceItemAdded.new(data: { product_id: product_id, order_id: order_id, price: 50 }))
    end

    def prepare_product(product_id)
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
    end

    def customer_registered(customer_id)
      event_store.publish(Crm::CustomerRegistered.new(data: { customer_id: customer_id, name: "Arkency" }))
    end

    def create_active_time_promotion
      run_command(
        Pricing::CreateTimePromotion.new(
          time_promotion_id: SecureRandom.uuid,
          discount: 50,
          start_time: Time.current - 1,
          end_time: Time.current + 1,
          label: "Last Minute"
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end

    def set_percentage_discount(order_id)
      run_command(
        Pricing::SetPercentageDiscount.new(order_id: order_id, amount: 10)
      )
    end

    def remove_percentage_discount(order_id)
      run_command(
        Pricing::RemovePercentageDiscount.new(order_id: order_id, type: Pricing::Discounts::GENERAL_DISCOUNT)
      )
    end
  end
end
