module Pricing
  class NotPossibleToAssignDiscountTwice < StandardError
  end

  class NotPossibleToResetWithoutDiscount < StandardError
  end

  class NotPossibleToChangeDiscount < StandardError
  end

  class OverlappingHappyHours < StandardError; end

  class SetPercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      stream_name = @repository.stream_name(Discounts::Order, cmd.order_id)
      order = build_order(stream_name)
      begin
        order.discount
      rescue NoMethodError
        raise NotPossibleToAssignDiscountTwice
      end
      @event_store.publish(
        PercentageDiscountSet.new(
          data: {
            order_id: cmd.order_id,
            amount: cmd.amount
          }
        ),
        stream_name: stream_name
      )
    end

    private

    def build_order(stream_name)
      last_event = last_event(stream_name)
      case last_event
      when PercentageDiscountSet, PercentageDiscountChanged
        nil
      else
        Discounts::Order.new
      end
    end

    def last_event(stream_name)
      @event_store.read.stream(stream_name).last
    end
  end

  class ResetPercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      stream_name = @repository.stream_name(Discounts::Order, cmd.order_id)
      order = build_order(stream_name)
      begin
        order.reset
      rescue NoMethodError
        raise NotPossibleToResetWithoutDiscount
      end
      @event_store.publish(
        PercentageDiscountReset.new(
          data: {
            order_id: cmd.order_id
          }
        ),
        stream_name: stream_name
      )
    end

    private

    def build_order(stream_name)
      last_event = last_event(stream_name)
      case last_event
      when PercentageDiscountSet, PercentageDiscountChanged
        Discounts::DiscountedOrder.new
      end
    end

    def last_event(stream_name)
      @event_store.read.stream(stream_name).last
    end
  end

  class ChangePercentageDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      stream_name = @repository.stream_name(Discounts::Order, cmd.order_id)
      order = build_order(stream_name)
      begin
        order.change_discount
      rescue NoMethodError
        raise NotPossibleToChangeDiscount
      end
      @event_store.publish(
        PercentageDiscountChanged.new(
          data: {
            order_id: cmd.order_id,
            amount: cmd.amount
          }
        ),
        stream_name: stream_name
      )
    end

    private

    def build_order(stream_name)
      last_event = last_event(stream_name)
      case last_event
      when PercentageDiscountSet, PercentageDiscountChanged
        Discounts::DiscountedOrder.new
      end
    end

    def last_event(stream_name)
      @event_store.read.stream(stream_name).last
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

  class CreateTimePromotionHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(TimePromotion, cmd.time_promotion_id) do |time_promotion|
        time_promotion.create(label: cmd.label, code: cmd.code)
      end
    end
  end

  class SetTimePromotionDiscountHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(TimePromotion, cmd.time_promotion_id) do |time_promotion|
        time_promotion.set_discount(discount: cmd.discount)
      end
    end
  end

  class SetTimePromotionRangeHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(TimePromotion, cmd.time_promotion_id) do |time_promotion|
        time_promotion.set_range(start_time: cmd.start_time, end_time: cmd.end_time)
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
      pricing_catalog = PricingCatalog.new(@event_store)
      promotions_calendar = PromotionsCalendar.new(@event_store)
      order_discount = build_percentage_discount(command.order_id)
      time_promotions_discount = wrap_percentage_discount(promotions_calendar.current_time_promotions_discount)
      percentage_discount = order_discount.add(time_promotions_discount)

      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.calculate_total_value(pricing_catalog, percentage_discount)
      end
    end

    def calculate_sub_amounts(command)
      pricing_catalog = PricingCatalog.new(@event_store)
      promotions_calendar = PromotionsCalendar.new(@event_store)
      order_discount = build_percentage_discount(command.order_id)
      time_promotions_discount = wrap_percentage_discount(promotions_calendar.current_time_promotions_discount)
      percentage_discount = order_discount.add(time_promotions_discount)

      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.calculate_sub_amounts(pricing_catalog, percentage_discount)
      end
    end

    private

    def build_percentage_discount(order_id)
      last_event = last_discount_order_event(order_id)
      amount = last_event.data.fetch(:amount) if percentage_discount_event?(last_event)

      wrap_percentage_discount(amount)
    end

    def last_discount_order_event(order_id)
      @event_store
        .read
        .stream(@repository.stream_name(Discounts::Order, order_id))
        .last
    end

    def percentage_discount_event?(event)
      [PercentageDiscountSet, PercentageDiscountChanged].any? { |event_type| event.instance_of?(event_type) }
    end

    def wrap_percentage_discount(amount)
      amount&.positive? ? Discounts::PercentageDiscount.new(amount) : Discounts::NoPercentageDiscount.new
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
end
