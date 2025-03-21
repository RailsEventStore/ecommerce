require_relative "test_helper"

module Pricing
  class DefaultPricingPolicyTest < Test
    cover "Pricing::DefaultPricingPolicy*"

    def setup
      @catalog = ConstantPriceCatalog.new(100)
    end

    def test_returns_catalog_price_when_no_discounts_added
      catalog = ConstantPriceCatalog.new(100)
      policy = DefaultPricingPolicy.new(catalog)
      product_id = SecureRandom.uuid
      calculated_prices = policy.apply([], product_id)

      assert_calculated_prices(
        calculated_prices,
        [product_id, 100, 100]
      )
    end

    def test_only_reads_catalog_when_adding_a_new_item
      catalog_1 = ConstantPriceCatalog.new(100)
      policy_1 = DefaultPricingPolicy.new(catalog_1)
      catalog_2 = ConstantPriceCatalog.new(123)
      policy_2 = DefaultPricingPolicy.new(catalog_2)
      product_id = SecureRandom.uuid
      calculated_prices_1 = policy_1.apply([], product_id)
      calculated_prices_2 = policy_2.apply(calculated_prices_1, product_id)

      assert_calculated_prices(
        calculated_prices_2,
        [product_id, 100, 100],
        [product_id, 123, 123]
      )
    end

    def test_adds_discount_to_calculated_prices_if_discount_added
      catalog = ConstantPriceCatalog.new(100)
      policy = DefaultPricingPolicy.new(catalog)
      product_id = SecureRandom.uuid
      policy.add_discount(Pricing::Discounts::PercentageDiscount.new(10))
      calculated_prices = policy.apply([], product_id)

      assert_calculated_prices(
        calculated_prices,
        [product_id, 100, 90]
      )
    end

    private

    def assert_calculated_prices(calculated_prices, *expected_prices)
      expected_prices.zip(calculated_prices).each do |(product_id, catalog_price, price), calculated|
        assert_equal(
          Pricing::Offer::ItemPrice.new(product_id, catalog_price, price), calculated
        )
      end
    end

    class ConstantPriceCatalog
      def initialize(price)
        @price = price
      end

      def price_by_product_id(_)
        @price
      end
    end
  end
end
