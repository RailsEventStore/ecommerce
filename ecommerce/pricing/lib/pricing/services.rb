module Pricing
  class NotPossibleToAssignDiscountTwice < StandardError
  end

  class NotPossibleToRemoveWithoutDiscount < StandardError
  end

  class NotPossibleToChangeDiscount < StandardError
  end

  class FreeProductAlreadyMade < StandardError
  end

  class FreeProductNotExists < StandardError
  end

  class CantAcceptEmptyOffer < StandardError
  end

  class CantModifyAcceptedOffer < StandardError
  end

  class CantModifyExpiredOffer < StandardError
  end

  class OnlyAcceptedOfferCanBeRejected < StandardError
  end

  class OnlyDraftOfferCanBeExpired < StandardError
  end

  class SetPercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @repository.with_aggregate(Offer, cmd.aggregate_id) do |order|
        order.apply_discount(
          Discounts::PercentageDiscount.new(cmd.amount),
          DefaultPricingPolicy.new(PricingCatalog.new(@event_store))
        )
      end
    end
  end

  class RemovePercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @repository.with_aggregate(Offer, cmd.aggregate_id) do |order|
        order.remove_discount(Discounts::GENERAL_DISCOUNT, DefaultPricingPolicy.new(PricingCatalog.new(@event_store)))
      end
    end
  end

  class ChangePercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Offer, cmd.aggregate_id) do |order|
        order.change_discount(
          Discounts::PercentageDiscount.new(cmd.amount),
          DefaultPricingPolicy.new(nil)
        )
      end
    end
  end

  class SetTimePromotionDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @repository.with_aggregate(Offer, cmd.aggregate_id) do |order|
        order.apply_discount(
          Discounts::PercentageDiscount.new(Discounts::TIME_PROMOTION_DISCOUNT, cmd.amount),
          DefaultPricingPolicy.new(PricingCatalog.new(@event_store))
        )
      end
    end
  end

  class RemoveTimePromotionDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @repository.with_aggregate(Offer, cmd.aggregate_id) do |order|
        order.remove_discount(
          Discounts::TIME_PROMOTION_DISCOUNT,
          DefaultPricingPolicy.new(PricingCatalog.new(@event_store))
        )
      end
    end
  end

  class SetPriceHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(PriceChange, cmd.product_id) do |product|
        product.set_price(cmd.price)
      end
    end
  end

  class SetFuturePriceHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.with_metadata({ valid_at: cmd.valid_since }) do
        @repository.with_aggregate(PriceChange, cmd.product_id) do |product|
          product.set_price(cmd.price)
        end
      end
    end
  end

  class CreateTimePromotionHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(TimePromotion, cmd.time_promotion_id) do |time_promotion|
        time_promotion.create(cmd.discount, cmd.start_time, cmd.end_time, cmd.label)
      end
    end
  end

  class OnAddItemToBasket
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(command)
      @repository.with_aggregate(Offer, command.aggregate_id) do |order|
        order.add_item(command.product_id, DefaultPricingPolicy.new(PricingCatalog.new(@event_store)))
      end
    end
  end

  class OnRemoveItemFromBasket
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Offer, command.aggregate_id) do |order|
        order.remove_item(command.product_id, command.catalog_price)
      end
    end
  end

  class OnCouponRegister
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Coupon, command.aggregate_id) do |coupon|
        coupon.register(command.name, command.code, command.discount)
      end
    end
  end

  class MakeProductFreeForOrderHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Offer, command.aggregate_id) do |order|
        order.make_product_free(command.order_id, command.product_id)
      end
    end
  end

  class RemoveFreeProductFromOrderHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Offer, command.aggregate_id) do |order|
        order.remove_free_product(command.order_id, command.product_id)
      end
    end
  end

  class UseCouponHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Offer, command.aggregate_id) do |order|
        order.use_coupon(command.coupon_id, command.discount)
      end
    end
  end

  class OnAcceptOffer
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Offer, command.aggregate_id) do |order|
        order.accept
      end
    end
  end

  class OnRejectOffer
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Offer, command.aggregate_id) do |order|
        order.reject
      end
    end
  end

  class OnExpireOffer
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Offer, command.aggregate_id) do |order|
        order.expire
      end
    end
  end
end
