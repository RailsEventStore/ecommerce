module Pricing
  class Offer
    include AggregateRoot

    InvalidState = Class.new(StandardError)

    def initialize(id)
      @id = id
      @discounts = []
      @state = :draft
    end

    def draft
      apply OfferDrafted.new(data: { order_id: @id })
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
      raise FreeProductAlreadyMade if @free_product
      apply ProductMadeFreeForOrder.new(
        data: {
          order_id: order_id,
          product_id: product_id
        }
      )
    end

    def remove_free_product(order_id, product_id)
      return unless @free_product
      apply FreeProductRemovedFromOrder.new(
        data: {
          order_id: order_id,
          product_id: product_id
        }
      )
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
      raise InvalidState.new("Only draft offer can be accepted") unless @state == :draft
      apply OfferAccepted.new(data: { order_id: @id })
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

    on OfferDrafted do |event|
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
      @free_product = event.data.fetch(:product_id)
    end

    on FreeProductRemovedFromOrder do |event|
      @free_product = nil
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
  end
end
