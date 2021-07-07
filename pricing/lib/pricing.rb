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
      pricing_catalog = PricingCatalog.new(Rails.configuration.event_store)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.calculate_total_value(pricing_catalog)
      end
    end
  end

  class PriceSet < RailsEventStore::Event
  end

  class OrderTotalValueCalculated < RailsEventStore::Event
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

    def calculate_total_value(pricing_catalog)
      total_value = @product_ids.sum do |product_id|
        pricing_catalog.price_for(product_id)
      end

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