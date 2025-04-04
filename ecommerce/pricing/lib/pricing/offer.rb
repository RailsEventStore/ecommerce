module Pricing
  class Offer
    include AggregateRoot

    InvalidState = Class.new(StandardError)
    IsEmpty = Class.new(StandardError)

    def initialize(id)
      @id = id
      @list = List.new
      @discounts = []
      @state = :draft
    end

    def add_item(product_id, price)
      apply PriceItemAdded.new(
        data: {
          order_id: @id,
          product_id: product_id,
          price: price,
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
      raise NotPossibleToAssignDiscountTwice if discount_exists?(discount.type)
      apply PercentageDiscountSet.new(
        data: {
          order_id: @id,
          type: discount.type,
          amount: discount.value
        }
      )
    end

    def change_discount(discount)
      raise NotPossibleToChangeDiscount unless discount_exists?(discount.type)
      apply PercentageDiscountChanged.new(
        data: {
          order_id: @id,
          type: discount.type,
          amount: discount.value
        }
      )
    end

    def remove_discount(type)
      raise NotPossibleToRemoveWithoutDiscount unless discount_exists?(type)
      apply PercentageDiscountRemoved.new(
        data: {
          order_id: @id,
          type: type
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
      return unless @list.contains_free_products?
      apply FreeProductRemovedFromOrder.new(
        data: {
          order_id: order_id,
          product_id: product_id
        }
      )
    end

    def calculate_total_value
      total_value = @list.base_sum
      discounted_value = @discounts.inject(Discounts::NoPercentageDiscount.new, :add).apply(total_value)

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

    def calculate_sub_amounts
      sub_amounts_total = @list.sub_amounts_total

      sub_amounts_total.each_pair do |product_id, h|
        apply(
          PriceItemValueCalculated.new(
            data: {
              order_id: @id,
              product_id: product_id,
              quantity: h[:quantity],
              amount: h[:amount],
              discounted_amount: @discounts.inject(Discounts::NoPercentageDiscount.new, :add).apply(h[:amount])
            }
          )
        )
      end
    end

    def use_coupon(coupon_id, discount)
      apply CouponUsed.new(
        data: {
          order_id: @id,
          coupon_id: coupon_id,
          discount: discount
        }
      )
    end

    def accept
      raise IsEmpty if @list.empty?
      raise InvalidState.new("Only draft offer can be accepted") unless @state == :draft
      apply OfferAccepted.new(
        data: {
          order_id: @id,
          order_lines: @list.quantities
        }
      )
    end

    def reject
      raise InvalidState.new("Only accepted offer can be rejected") unless @state == :accepted
      apply OfferRejected.new(data: { order_id: @id })
    end

    def expire
      raise InvalidState.new("Only draft offer can be expired") unless @state == :draft
      apply OfferExpired.new(data: { order_id: @id })
    end

    private

    on PriceItemAdded do |event|
      @list.add_item(event.data.fetch(:product_id), event.data.fetch(:price))
    end

    on PriceItemRemoved do |event|
      @list.remove_item(event.data.fetch(:product_id))
    end

    on PriceItemValueCalculated do |event|
    end

    on OrderTotalValueCalculated do |event|
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
      @list.set_free(event.data.fetch(:product_id))
    end

    on FreeProductRemovedFromOrder do |event|
      @list.restore_nonfree(event.data.fetch(:product_id))
    end

    on CouponUsed do |event|
    end

    on OfferAccepted do |event|
      @state = :accepted
    end

    on OfferRejected do |event|
      @state = :draft
    end

    on OfferExpired do |event|
      @state = :expired
    end

    def discount_exists?(type)
      @discounts.find { |discount| discount.type == type }
    end

    class List
      Item = Data.define(:product_id, :quantity, :price, :catalog_price) do
        def initialize(product_id:, quantity:, price:, catalog_price: price) = super
      end

      def initialize
        @items = []
      end

      def add_item(product_id, price)
        @items << Item.new(product_id:, price:, quantity: 1)
      end

      def remove_item(product_id)
        new_items = @items.sort {|x,y| x.price <=> y.price }
        index_of_item_to_remove = new_items.index { |item| item.product_id == product_id }
        new_items.delete_at(index_of_item_to_remove)
        @items = new_items
      end

      def contains_free_products?
        @items.any? { |item| item.price == 0 }
      end

      def base_sum
        @items.sum(&:price)
      end

      def sub_amounts_total
        @items.each_with_object({}) do |item, memo|
          memo[item.product_id] ||= { amount: 0, quantity: 0 }
          memo[item.product_id][:amount] += item.price * item.quantity
          memo[item.product_id][:quantity] += item.quantity
        end
      end

      def set_free(product_id)
        idx = @items.index { |item| item.product_id == product_id && item.price != 0 }
        old_item = @items.delete_at(idx)
        @items << old_item.with(price: 0)
      end

      def restore_nonfree(product_id)
        idx = @items.index { |item| item.product_id == product_id && item.price == 0 }
        old_item = @items.delete_at(idx)
        @items << old_item.with(price: old_item.catalog_price)
      end

      def quantities
        sub_amounts_total.map do |product_id, h|
          { product_id:, quantity: h[:quantity] }
        end
      end

      def empty?
        @items.empty?
      end
    end
  end
end
