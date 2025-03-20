module Pricing
  class Offer
    include AggregateRoot

    def initialize(id)
      @id = id
      @items = []
      @discounts = []
      @accepted = false
    end

    def add_item(product_id, pricing_policy)
      fail_if_accepted
      apply_discounts_to_pricing_policy(pricing_policy)
      items = pricing_policy.apply(@items, product_id)
      apply PriceItemAdded.new(
        data: {
          order_id: @id,
          product_id: product_id,
          catalog_price: items.last.catalog_price,
          price: items.last.price,
        }
      )
    end

    def remove_item(product_id, catalog_price)
      fail_if_accepted
      item = @items.find { |item| item.product_id == product_id && item.catalog_price == catalog_price }
      return unless item
      apply PriceItemRemoved.new(
        data: {
          order_id: @id,
          product_id: product_id,
          catalog_price: item.catalog_price,
          price: item.price,
        }
      )
    end

    def apply_discount(discount, pricing_policy)
      fail_if_accepted
      raise NotPossibleToAssignDiscountTwice if discount_exists?(discount.type)
      apply PercentageDiscountSet.new(
        data: {
          order_id: @id,
          type: discount.type,
          amount: discount.value
        }
      )
      apply_discounts_to_pricing_policy(pricing_policy)
      recalculate_prices(pricing_policy)
    end

    def change_discount(discount, pricing_policy)
      fail_if_accepted
      raise NotPossibleToChangeDiscount unless discount_exists?(discount.type)
      apply PercentageDiscountChanged.new(
        data: {
          order_id: @id,
          type: discount.type,
          amount: discount.value
        }
      )
      apply_discounts_to_pricing_policy(pricing_policy)
      recalculate_prices(pricing_policy)
    end

    def remove_discount(type, pricing_policy)
      fail_if_accepted
      raise NotPossibleToRemoveWithoutDiscount unless discount_exists?(type)
      apply PercentageDiscountRemoved.new(
        data: {
          order_id: @id,
          type: type
        }
      )
      apply_discounts_to_pricing_policy(pricing_policy)
      recalculate_prices(pricing_policy)
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

    def use_coupon(coupon_id, discount)
      fail_if_accepted
      apply CouponUsed.new(
        data: {
          order_id: @id,
          coupon_id: coupon_id,
          discount: discount
        }
      )
    end

    def accept
      apply OfferAccepted.new(
        data: {
          order_id: @id,
          amount: @items.sum(&:price),
          order_items: @items.map do |item|
            {
              product_id: item.product_id,
              catalog_price: item.catalog_price,
              price: item.price
            }
          end
        }
      )
    end

    private

    def fail_if_accepted
      raise CantModifyAcceptedOffer if @accepted
    end

    def apply_discounts_to_pricing_policy(pricing_policy)
      @discounts.each {|discount| pricing_policy.add_discount(discount) }
    end

    def recalculate_prices(pricing_policy)
      new_items = pricing_policy.apply(@items)
      apply OfferItemsPricesRecalculated.new(
        data: {
          order_id: @id,
          order_items: new_items.map do |item|
            {
              product_id: item.product_id,
              catalog_price: item.catalog_price,
              price: item.price
            }
          end
        }
      )
    end

    on PriceItemAdded do |event|
      @items << ItemPrice.new(event.data.fetch(:product_id), event.data.fetch(:catalog_price), event.data.fetch(:price))
    end

    on PriceItemRemoved do |event|
      i = @items.index(ItemPrice.new(event.data.fetch(:product_id), event.data.fetch(:catalog_price), event.data.fetch(:price)))
      @items.delete_at(i)
    end

    on OfferItemsPricesRecalculated do |event|
      @items = event.data.fetch(:order_items).map do |item|
        ItemPrice.new(item.fetch(:product_id), item.fetch(:catalog_price), item.fetch(:price))
      end
    end

    on PercentageDiscountSet do |event|
      @discounts << Discounts::PercentageDiscount.new(event.data.fetch(:type), event.data.fetch(:amount))
    end

    on PercentageDiscountChanged do |event|
      @discounts.delete_if { |discount| discount.type == event.data.fetch(:type) }
      @discounts << Discounts::PercentageDiscount.new(event.data.fetch(:type), event.data.fetch(:amount))
    end

    on PercentageDiscountRemoved do |event|
      @discounts.delete_if { |discount| discount.type == event.data.fetch(:type) }
    end

    on ProductMadeFreeForOrder do |event|
      @list.replace(Product, FreeProduct, event.data.fetch(:product_id))
    end

    on FreeProductRemovedFromOrder do |event|
      @list.replace(FreeProduct, Product, event.data.fetch(:product_id))
    end

    on CouponUsed do |event|
    end

    on OfferAccepted do |event|
      @accepted = true
    end

    def discount_exists?(type)
      @discounts.find { |discount| discount.type == type }
    end

    ItemPrice = Data.define(:product_id, :catalog_price, :price)

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

      def sub_discounts(pricing_catalog, discounts)
        @products_quantities.map do |product, quantity|
          catalog_price_for_single = pricing_catalog.price_for(product)
          with_total_discount_single = discounts.inject(Discounts::NoPercentageDiscount.new, :add).apply(catalog_price_for_single)
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
