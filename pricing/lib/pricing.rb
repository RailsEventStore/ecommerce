module Pricing
  class SetPrice < Command
    attribute :product_id, Types::Coercible::Integer
    attribute :price, Types::Coercible::Integer
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

  class PriceSet < RailsEventStore::Event

  end

  class Product
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def set_price(price)
      apply(PriceSet.new(data: {product_id: @id, price: price}))
    end

    private

    def apply_price_set(_)
    end
  end
end