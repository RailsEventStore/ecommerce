module Pricing
  class Order
    include AggregateRoot

    def initialize(id)
      @id = id
      @list = List.new
      @discount = Discounts::NoPercentageDiscount.new
    end

    def add_item(product_id)
      apply PriceItemAdded.new(
        data: {
          order_id: @id,
          product_id: product_id
        }
      )
    end

    def remove_item(product_id)
      apply PriceItemRemoved.new(
        data: {
          order_id: @id,
          product_id: product_id
        }
      )
    end

    def apply_discount(discount)
      raise NotPossibleToAssignDiscountTwice if @discount.exists?
      apply PercentageDiscountSet.new(
        data: {
          order_id: @id,
          amount: discount.value
        }
      )
    end

    def change_discount(discount)
      raise NotPossibleToChangeDiscount unless @discount.exists?
      apply PercentageDiscountChanged.new(
        data: {
          order_id: @id,
          amount: discount.value
        }
      )
    end

    def reset_discount
      raise NotPossibleToResetWithoutDiscount unless @discount.exists?
      apply PercentageDiscountReset.new(
        data: {
          order_id: @id
        }
      )
    end

    def make_product_free(order_id, product_id)
      raise FreeProductAlreadyMade if @list.contains_free_products?
      apply ProductMadeFreeForOrder.new(
        data: {
          order_id: order_id,
          product_id: product_id
        }
      )
    end

    def remove_free_product(order_id, product_id)
      raise FreeProductNotExists unless @list.contains_free_products?
      apply FreeProductRemovedFromOrder.new(
        data: {
          order_id: order_id,
          product_id: product_id
        }
      )
    end

    def calculate_total_value(pricing_catalog, time_promotion_discount)
      total_value = @list.base_sum(pricing_catalog)

      discounted_value = @discount.add(time_promotion_discount).apply(total_value)
      apply(
        OrderTotalValueCalculated.new(
          data: {
            order_id: @id,
            total_amount: total_value,
            discounted_amount: discounted_value
          }
        )
      )
    end

    def calculate_sub_amounts(pricing_catalog, time_promotions_discount)
      sub_amounts_total = @list.sub_amounts_total(pricing_catalog)
      sub_discounts = calculate_total_sub_discounts(pricing_catalog, time_promotions_discount)

      products = @list.products
      quantities = @list.quantities
      products.zip(quantities, sub_amounts_total, sub_discounts) do |product, quantity, sub_amount, sub_discount|
        apply(
          PriceItemValueCalculated.new(
            data: {
              order_id: @id,
              product_id: product.id,
              quantity: quantity,
              amount: sub_amount,
              discounted_amount: sub_amount - sub_discount
            }
          )
        )
      end
    end

    private

    on PriceItemAdded do |event|
      @list.add_item(Product.new(event.data.fetch(:product_id)))
    end

    on PriceItemRemoved do |event|
      @list.remove_item(event.data.fetch(:product_id))
    end

    on PriceItemValueCalculated do |event|
    end

    on OrderTotalValueCalculated do |event|
    end

    on PercentageDiscountSet do |event|
      @discount = Discounts::PercentageDiscount.new(event.data.fetch(:amount))
    end

    on PercentageDiscountChanged do |event|
      @discount = Discounts::PercentageDiscount.new(event.data.fetch(:amount))
    end

    on PercentageDiscountReset do |event|
      @discount = Discounts::NoPercentageDiscount.new
    end

    on ProductMadeFreeForOrder do |event|
      @list.replace(Product, FreeProduct, event.data.fetch(:product_id))
    end

    on FreeProductRemovedFromOrder do |event|
      @list.replace(FreeProduct, Product, event.data.fetch(:product_id))
    end

    def calculate_total_sub_discounts(pricing_catalog, time_promotions_discount)
      @list.sub_discounts(pricing_catalog, time_promotions_discount, @discount)
    end

    class List

      def initialize
        @products_quantities = Hash.new(0)
      end

      def add_item(product)
        @products_quantities[product] += 1
      end

      def remove_item(product_id)
        @products_quantities[Product.new(product_id)] -= 1
        clear_empty_products
      end

      def clear_empty_products
        @products_quantities.delete_if { |_, value| value.zero? }
      end

      def replace(from, to, product_id)
        @products_quantities[from.new(product_id)] -= 1
        @products_quantities[to.new(product_id)] += 1
        clear_empty_products
      end

      def products
        @products_quantities.keys
      end

      def quantities
        @products_quantities.values
      end

      def contains_free_products?
        @products_quantities.keys.any? {|key| key.free? }
      end

      def base_sum(pricing_catalog)
        @products_quantities.sum { |product, qty| pricing_catalog.price_for(product) * qty }
      end

      def sub_amounts_total(pricing_catalog)
        @products_quantities.map { |product, quantity| quantity * pricing_catalog.price_for(product) }
      end

      def sub_discounts(pricing_catalog, time_promotions_discount, discount)
        @products_quantities.map do |product, quantity|
          catalog_price_for_single = pricing_catalog.price_for(product)
          with_total_discount_single = discount.add(time_promotions_discount).apply(catalog_price_for_single)
          quantity * (catalog_price_for_single - with_total_discount_single)
        end
      end
    end

    class Product
      attr_reader :id

      def initialize(id)
        @id = id
      end

      def free?
      end

      def eql?(other)
        other.instance_of?(Product) && id.eql?(other.id)
      end

      alias == eql?

      def hash
        Product.hash ^ id.hash
      end
    end

    class FreeProduct
      attr_reader :id

      def initialize(id)
        @id = id
      end

      def free?
        true
      end

      def eql?(other)
        other.instance_of?(FreeProduct) && id.eql?(other.id)
      end

      alias == eql?

      def hash
        FreeProduct.hash ^ id.hash
      end
    end
  end
end
