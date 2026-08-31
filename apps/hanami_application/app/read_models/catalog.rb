# auto_register: false
# frozen_string_literal: true

module HanamiApplication
  module ReadModels
    class Catalog
      Product = Data.define(:id, :name, :price)

      def initialize(products)
        @products = products
      end

      def subscribe(event_store)
        handlers.each { |event_type, handler| event_store.subscribe(handler, to: [event_type]) }
      end

      def all
        @products.order(:name).to_a.map { |row| build(row) }
      end

      def find(product_id)
        build(@products.by_pk(product_id).one!)
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
        @products.insert(id: event.data.fetch(:product_id))
      end

      def name_product(event)
        @products.by_pk(event.data.fetch(:product_id)).update(name: event.data.fetch(:name))
      end

      def set_price(event)
        @products.by_pk(event.data.fetch(:product_id)).update(price: event.data.fetch(:price))
      end

      def build(row)
        Product.new(id: row[:id], name: row[:name], price: row[:price])
      end
    end
  end
end
