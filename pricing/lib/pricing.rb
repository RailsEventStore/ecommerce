require_relative 'discounts'

module Pricing

  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.register_command(AddItemToBasket, OnAddItemToBasket.new, ItemAddedToBasket)
      @cqrs.register_command(RemoveItemFromBasket, OnRemoveItemFromBasket.new, ItemRemovedFromBasket)
      @cqrs.register_command(SetPrice, SetPriceHandler.new, PriceSet)
      @cqrs.register_command(CalculateTotalValue, OnCalculateTotalValue.new, OrderTotalValueCalculated)
      @cqrs.register_command(SetPercentageDiscount, SetPercentageDiscountHandler.new, PercentageDiscountSet)
      @cqrs.subscribe(
        -> (event) { @cqrs.run(Pricing::CalculateTotalValue.new(order_id: event.data.fetch(:order_id)))},
        [Pricing::PercentageDiscountSet])
    end
  end

  class AddItemToBasket < Command
    attribute :order_id, Types::UUID
    attribute :product_id, Types::UUID

    alias :aggregate_id :order_id
  end

  class RemoveItemFromBasket < Command
    attribute :order_id, Types::UUID
    attribute :product_id, Types::UUID

    alias :aggregate_id :order_id
  end

  class CalculateTotalValue < Command
    attribute :order_id, Types::UUID
    alias :aggregate_id :order_id
  end

  class SetPrice < Command
    attribute :product_id, Types::UUID
    attribute :price, Types::Price
  end

  class ItemAddedToBasket < Event
    attribute :order_id,   Types::UUID
    attribute :product_id, Types::UUID
  end

  class ItemRemovedFromBasket < Event
    attribute :order_id,   Types::UUID
    attribute :product_id, Types::UUID
  end

  class SetPercentageDiscount < Command
    attribute :order_id,   Types::UUID
    attribute :amount, Types::PercentageDiscount
  end

  class NotPossibleToAssignDiscountTwice < StandardError; end

  class SetPercentageDiscountHandler
    include CommandHandler

    def call(cmd)
      stream_name = stream_name(Discounts::Order, cmd.order_id)
      order = build_order(stream_name)
      begin
        order.discount
      rescue NoMethodError
        raise NotPossibleToAssignDiscountTwice
      end
      Rails.configuration.event_store.publish(
        PercentageDiscountSet.new(data: {order_id: cmd.order_id, amount: cmd.amount}),
        stream_name: stream_name
      )
    end

    private

    def build_order(stream_name)
      last_event = last_event(stream_name)
      case last_event
      when PercentageDiscountSet
        nil
      else
        Discounts::Order.new
      end
    end

    def last_event(stream_name)
      Rails.configuration.event_store.read.stream(stream_name).last
    end
  end

  class SetPriceHandler
    include CommandHandler

    def call(cmd)
      repository = AggregateRoot::Repository.new(Rails.configuration.event_store)
      stream_name = stream_name(Product, cmd.product_id)
      product = repository.load(Product.new(cmd.product_id), stream_name)
      product.set_price(cmd.price)
      repository.store(product, stream_name)
    end
  end

  class OnAddItemToBasket
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.add_item(command.product_id)
      end
    end
  end

  class OnRemoveItemFromBasket
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.remove_item(command.product_id)
      end
    end
  end

  class OnCalculateTotalValue
    include CommandHandler

    def call(command)
      event_store = Rails.configuration.event_store
      pricing_catalog = PricingCatalog.new(event_store)
      percentage_discount = build_percentage_discount(command.order_id)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.calculate_total_value(pricing_catalog, percentage_discount)
      end
    end

    private

    def build_percentage_discount(order_id)
      last_event = last_discount_order_event(order_id)
      case last_event
      when PercentageDiscountSet
        Discounts::PercentageDiscount.new(last_event.data.fetch(:amount))
      else
        Discounts::NoPercentageDiscount.new
      end
    end

    def last_discount_order_event(order_id)
      Rails.configuration.event_store.read.stream(stream_name(Discounts::Order, order_id)).last
    end
  end

  class PriceSet < Event
    attribute :product_id, Types::UUID
    attribute :price, Types::Price
  end

  class OrderTotalValueCalculated < RailsEventStore::Event
  end

  class PercentageDiscountSet < Event
    attribute :order_id, Types::UUID
    attribute :amount, Types::Price
  end

  class PercentageDiscountReset < RailsEventStore::Event
  end

  class Order
    include AggregateRoot

    def initialize(id)
      @id = id
      @product_ids = []
    end

    def add_item(product_id)
      apply ItemAddedToBasket.new(data: {order_id: @id, product_id: product_id})
    end

    def remove_item(product_id)
      apply ItemRemovedFromBasket.new(data: {order_id: @id, product_id: product_id})
    end

    def calculate_total_value(pricing_catalog, percentage_discount)
      total_value = @product_ids.sum do |product_id|
        pricing_catalog.price_for(product_id)
      end
      total_value = percentage_discount.apply(total_value)
      apply(OrderTotalValueCalculated.new(data: {order_id: @id, amount: total_value}))
    end

    on ItemAddedToBasket do |event|
      @product_ids << event.data.fetch(:product_id)
    end

    on ItemRemovedFromBasket do |event|
      @product_ids.delete(event.data.fetch(:product_id))
    end

    on OrderTotalValueCalculated do |event|
    end
  end

  class Product
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def set_price(price)
      apply(PriceSet.new(data: { product_id: @id, price: price }))
    end

    private

    def apply_price_set(_)
    end
  end

  class PricingCatalog
    def initialize(event_store)
      @event_store = event_store
    end

    def price_for(product_id)
      @event_store.read.of_type(PriceSet).to_a.filter{|e| e.data.fetch(:product_id).eql?(product_id)}.last.data.fetch(:price)
    end
  end
end