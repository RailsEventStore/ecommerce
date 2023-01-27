require "test_helper"

module ClientOrders
  class ProductPriceChangedTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_reflects_change
      product_id = prepare_product
      unchanged_product_id = prepare_product

      set_price(product_id, 100)

      assert_equal 100, Product.find_by_uid(product_id).price
      assert_equal 50, Product.find_by_uid(unchanged_product_id).price
    end

    def test_registers_lowest_recent_price
      product_id = prepare_product

      set_price(product_id, 40)

      assert_equal 40, Product.find_by_uid(product_id).lowest_recent_price
    end

    def test_keeps_lowest_recent_price
      product_id = prepare_product

      set_price(product_id, 100)
      set_price(product_id, 20)
      set_price(product_id, 50)
      set_price(product_id, 70)

      assert_equal 20, Product.find_by_uid(product_id).lowest_recent_price
    end

    def test_takes_into_account_price_set_before_30_days
      product_id = prepare_product

      set_price(product_id, 100)
      set_past_price(product_id, 15, 31.days.ago.beginning_of_day.to_s)
      set_price(product_id, 50)
      set_price(product_id, 70)

      assert_equal 15, Product.find_by_uid(product_id).lowest_recent_price
    end

    def test_ignores_prices_older_than_30_days
      product_id = prepare_product

      Timecop.freeze(Time.now) do
        set_past_price(product_id, 20, 31.days.ago.beginning_of_day.to_s)
        set_past_price(product_id, 25, (30.days.ago.beginning_of_day - 1.second).to_s)
        set_past_price(product_id, 30, 30.days.ago.beginning_of_day.to_s)
        set_past_price(product_id, 32, (30.days.ago.beginning_of_day + 1.second).to_s)
        set_past_price(product_id, 35, 30.days.ago.to_s)
        set_past_price(product_id, 40, 29.days.ago.beginning_of_day.to_s)

        assert_equal 30, Product.find_by_uid(product_id).lowest_recent_price
      end
    end

    def test_ignores_future_prices
      product_id = prepare_product

      set_past_price(product_id, 45, 2.days.ago.to_s)
      set_price(product_id, 35)
      set_future_price(product_id, 11, (Time.now + 2.days).to_s)

      assert_equal 35, Product.find_by_uid(product_id).lowest_recent_price
    end

    def test_ignores_other_products
      product1_id = prepare_product
      product2_id = prepare_product

      set_price(product1_id, 35)
      set_price(product2_id, 25)
      set_price(product1_id, 30)

      assert_equal 30, Product.find_by_uid(product1_id).lowest_recent_price
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

    def set_price(product_id, amount)
      run_command(Pricing::SetPrice.new(product_id: product_id, price: amount))
    end

    def set_future_price(product_id, amount, valid_since)
      run_command(Pricing::SetFuturePrice.new(product_id: product_id, price: amount, valid_since: valid_since))
    end
    alias set_past_price set_future_price
  end
end
