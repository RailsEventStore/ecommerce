module Pricing
  class AddItemToBasket < Command
    attribute :order_id, Types::UUID
    attribute :product_id, Types::Coercible::Integer

    alias :aggregate_id :order_id
  end

  class RemoveItemFromBasket < Command
    attribute :order_id, Types::UUID
    attribute :product_id, Types::Coercible::Integer

    alias :aggregate_id :order_id
  end

  class SetPrice < Command
    attribute :product_id, Types::Coercible::Integer
    attribute :price, Types::Price
  end

  class ItemAddedToBasket < Event
    attribute :order_id,   Types::UUID
    attribute :product_id, Types::ID
  end

  class ItemRemovedFromBasket < Event
    attribute :order_id,   Types::UUID
    attribute :product_id, Types::ID
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

  class PriceSet < RailsEventStore::Event

  end

  class Order
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def add_item(product_id)
      apply ItemAddedToBasket.new(data: {order_id: @id, product_id: product_id})
    end

    def remove_item(product_id)
      apply ItemRemovedFromBasket.new(data: {order_id: @id, product_id: product_id})
    end

    on ItemAddedToBasket do |event|
    end

    on ItemRemovedFromBasket do |event|
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
end