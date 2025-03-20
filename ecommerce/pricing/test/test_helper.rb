require "minitest/autorun"
require "mutant/minitest/coverage"
require "active_support/all"

require_relative "../lib/pricing"

module Pricing
  class Test < Infra::InMemoryTest

    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end

    private

    def set_price(product_id, amount)
      run_command(SetPrice.new(product_id: product_id, price: amount))
    end

    def set_future_price(product_id, amount, valid_since)
      run_command(SetFuturePrice.new(product_id: product_id, price: amount, valid_since: valid_since))
    end

    def calculate_total_value(order_id)
      run_command(CalculateTotalValue.new(order_id: order_id))
    end

    def add_item(order_id, product_id)
      run_command(
        AddPriceItem.new(order_id: order_id, product_id: product_id)
      )
    end

    def remove_item(order_id, product_id, catalog_price)
      run_command(
        RemovePriceItem.new(order_id: order_id, product_id: product_id, catalog_price: catalog_price)
      )
    end

    def register_coupon(uid, name, code, discount)
      run_command(RegisterCoupon.new(coupon_id: uid, name: name, code: code, discount: discount))
    end

    def use_coupon(order_id, coupon_id, discount)
      run_command(UseCoupon.new(order_id: order_id, coupon_id: coupon_id, discount: discount))
    end

    def set_time_promotion_discount(order_id, amount)
      run_command(SetTimePromotionDiscount.new(order_id: order_id, amount: amount))
    end

    def remove_time_promotion_discount(order_id)
      run_command(RemoveTimePromotionDiscount.new(order_id: order_id))
    end

    def set_percentage_discount(order_id, amount)
      run_command(SetPercentageDiscount.new(order_id: order_id, amount: amount))
    end

    def remove_percentage_discount(order_id)
      run_command(RemovePercentageDiscount.new(order_id: order_id))
    end

    def fake_name
      "Fake name"
    end
  end
end
