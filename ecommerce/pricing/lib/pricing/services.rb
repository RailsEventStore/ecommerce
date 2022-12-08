module Pricing
  class NotPossibleToAssignDiscountTwice < StandardError
  end

  class NotPossibleToResetWithoutDiscount < StandardError
  end

  class NotPossibleToChangeDiscount < StandardError
  end

  class OverlappingHappyHours < StandardError; end

  class FreeProductAlreadyMade < StandardError
  end

  class FreeProductNotExists < StandardError
  end

  class SetPercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Order, cmd.aggregate_id) do |order|
        order.apply_discount(Discounts::PercentageDiscount.new(cmd.amount))
      end
    end
  end

  class ResetPercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Order, cmd.aggregate_id) do |order|
        order.reset_discount
      end
    end
  end

  class ChangePercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Order, cmd.aggregate_id) do |order|
        order.change_discount(Discounts::PercentageDiscount.new(cmd.amount))
      end
    end
  end

  class SetPriceHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Product, cmd.product_id) do |product|
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
        @repository.with_aggregate(Product, cmd.product_id) do |product|
          product.set_price(cmd.price)
          if cmd.valid_since
            product.set_future_price(cmd.price, cmd.valid_since)
          end
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
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.add_item(command.product_id)
      end
    end
  end

  class OnRemoveItemFromBasket
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.remove_item(command.product_id)
      end
    end
  end

  class OnCalculateTotalValue
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.calculate_total_value(PricingCatalog.new(@event_store), time_promotions_discount)
      end
    end

    def calculate_sub_amounts(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.calculate_sub_amounts(PricingCatalog.new(@event_store), time_promotions_discount)
      end
    end

    private

    def time_promotions_discount
      promotions_calendar = PromotionsCalendar.new(@event_store)
      time_promotions_discount = promotions_calendar.current_time_promotions_discount
      if time_promotions_discount.zero?
        time_percentage_discount = Discounts::NoPercentageDiscount.new
      else
        time_percentage_discount = Discounts::PercentageDiscount.new(time_promotions_discount)
      end
      time_percentage_discount
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
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.make_product_free(command.order_id, command.product_id)
      end
    end
  end

  class RemoveFreeProductFromOrderHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.remove_free_product(command.order_id, command.product_id)
      end
    end
  end
end
