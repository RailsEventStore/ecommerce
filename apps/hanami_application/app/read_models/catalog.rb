# auto_register: false
# frozen_string_literal: true

module HanamiApplication
  module ReadModels
    class Catalog
      Product = Data.define(:id, :name, :price)

      def initialize
        @products = {}
      end

      def subscribe(event_store)
        handlers.each { |event_type, handler| event_store.subscribe(handler, to: [event_type]) }
      end

      def apply(event)
        handlers[event.class]&.call(event)
      end

      def all
        @products.values.sort_by { |product| product.name.to_s }
      end

      def find(product_id)
        @products.fetch(product_id)
      end

      private

      def handlers
        {
          ProductCatalog::ProductRegistered => method(:register_product),
          ProductCatalog::ProductNamed => method(:name_product),
          Pricing::PriceSet => method(:set_price)
        }
      end

      def register_product(event)
        product_id = event.data.fetch(:product_id)
        @products[product_id] = Product.new(id: product_id, name: nil, price: nil)
      end

      def name_product(event)
        update(event.data.fetch(:product_id)) do |product|
          product.with(name: event.data.fetch(:name))
        end
      end

      def set_price(event)
        update(event.data.fetch(:product_id)) do |product|
          product.with(price: event.data.fetch(:price))
        end
      end

      def update(product_id)
        @products[product_id] = yield(@products.fetch(product_id))
      end
    end
  end
end
