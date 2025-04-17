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

    def add_item(product_id, base_price, promotion = nil)
      if promotion
        price = promotion.apply(@list.quantities, product_id, base_price)
      else
        price = @discounts.inject(Discounts::NoPercentageDiscount.new, :add).apply(base_price)
      end

      data = {
        order_id: @id,
        product_id: product_id,
        base_price: base_price,
        price: price,
        base_total_value: @list.base_sum + base_price,
        total_value: @list.actual_sum + price,
      }

      data[:applied_promotion] = promotion.class.name if promotion

      apply PriceItemAdded.new(data:)
    end

    def remove_item(product_id)
      item = @list.lowest_price_item(product_id)
      apply PriceItemRemoved.new(
        data: {
          order_id: @id,
          product_id: product_id,
          base_price: item.base_price,
          price: item.price,
          base_total_value: @list.base_sum - item.base_price,
          total_value: @list.actual_sum - item.price
        }
      )
    end

    def apply_discount(discount)
      raise NotPossibleToAssignDiscountTwice if discount_exists?(discount.type)
      apply PercentageDiscountSet.new(
        data: {
          order_id: @id,
          type: discount.type,
          amount: discount.value,
          base_total_value: @list.base_sum,
          total_value: @list.actual_sum - @list.actual_sum * (discount.value / 100)
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
      discounted_value = @list.actual_sum

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
              quantity: h.fetch(:quantity),
              amount: h.fetch(:base_amount),
              discounted_amount: h.fetch(:amount),
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

    def reject(reason, unavailable_product_ids)
      raise InvalidState.new("Only accepted offer can be rejected") unless @state == :accepted
      apply OfferRejected.new(data: {
        order_id: @id,
        reason:,
        unavailable_product_ids:
      })
    end

    def expire
      raise InvalidState.new("Only draft offer can be expired") unless @state == :draft
      apply OfferExpired.new(data: { order_id: @id })
    end

    private

    on PriceItemAdded do |event|
      @list.add_item(event.data.fetch(:product_id), event.data.fetch(:base_price), event.data.fetch(:price))
    end

    on PriceItemRemoved do |event|
      @list.remove_item(event.data.fetch(:product_id), event.data.fetch(:price))
    end

    on PriceItemValueCalculated do |event|
    end

    on OrderTotalValueCalculated do |event|
    end

    on PercentageDiscountSet do |event|
      @discounts << Discounts::PercentageDiscount.new(event.data.fetch(:type), event.data.fetch(:amount))
      @list.apply_discounts(@discounts)
    end

    on PercentageDiscountChanged do |event|
      @discounts.delete_if { |discount| discount.type == event.data.fetch(:type) }
      @discounts << Discounts::PercentageDiscount.new(event.data.fetch(:type), event.data.fetch(:amount))
      @list.apply_discounts(@discounts)
    end

    on PercentageDiscountRemoved do |event|
      @discounts.delete_if { |discount| discount.type == event.data.fetch(:type) }
      @list.apply_discounts(@discounts)
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
      Item = Data.define(:product_id, :quantity, :base_price, :price)

      def initialize
        @items = []
      end

      def add_item(product_id, base_price, price)
        @items << Item.new(product_id:, base_price:, price:, quantity: 1)
      end

      def remove_item(product_id, price)
        index_of_item_to_remove = @items.index { |item| item.product_id == product_id && item.price == price }
        @items.delete_at(index_of_item_to_remove)
      end

      def apply_discounts(discounts)
        @items = @items.map do |item|
          next item if is_free?(item)
          price = discounts.inject(Discounts::NoPercentageDiscount.new, :add).apply(item.base_price)
          item.with(price:)
        end
      end

      def is_free?(item)
        item.price == 0
      end

      def contains_free_products?
        @items.any? { |item| item.price == 0 }
      end

      def base_sum
        @items.sum(&:base_price)
      end

      def actual_sum
        @items.sum(&:price)
      end

      def sub_amounts_total
        @items.each_with_object({}) do |item, memo|
          memo[item.product_id] ||= { base_amount: 0, amount: 0, quantity: 0 }
          memo[item.product_id][:base_amount] += item.base_price * item.quantity
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
        return unless idx
        old_item = @items.delete_at(idx)
        @items << old_item.with(price: old_item.base_price)
      end

      def lowest_price_item(product_id)
        @items
          .select { |item| item.product_id == product_id }
          .sort_by(&:price)
          .first
      end

      def quantities
        sub_amounts_total.map do |product_id, h|
          { product_id:, quantity: h.fetch(:quantity) }
        end
      end

      def empty?
        @items.empty?
      end
    end
  end
end
