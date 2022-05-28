module Pricing
  class NotPossibleToAssignDiscountTwice < StandardError
  end

  class NotPossibleToResetWithoutDiscount < StandardError
  end

  class NotPossibleToChangeDiscount < StandardError
  end

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

  class CreateHappyHourHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Product, cmd.product_id) do |product|
        product.create_happy_hour(cmd.discount, cmd.start_hour, cmd.end_hour)
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
      percentage_discount = build_percentage_discount(command.order_id)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.calculate_total_value(pricing_catalog, percentage_discount)
      end
    end

    def calculate_sub_amounts(command)
      pricing_catalog = PricingCatalog.new(@event_store)
      percentage_discount = build_percentage_discount(command.order_id)
      @repository.with_aggregate(Order, command.aggregate_id) do |order|
        order.calculate_sub_amounts(pricing_catalog, percentage_discount)
      end
    end

    private

    def build_percentage_discount(order_id)
      last_event = last_discount_order_event(order_id)
      case last_event
      when PercentageDiscountSet, PercentageDiscountChanged
        Discounts::PercentageDiscount.new(last_event.data.fetch(:amount))
      else
        Discounts::NoPercentageDiscount.new
      end
    end

    def last_discount_order_event(order_id)
      @event_store
        .read
        .stream(@repository.stream_name(Discounts::Order, order_id))
        .last
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
