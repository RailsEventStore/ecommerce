module Products
  class Product < ApplicationRecord
    self.table_name = "products"
  end

  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.subscribe(-> (event) { register_product(event) }, [ProductCatalog::ProductRegistered])
      copy(ProductCatalog::ProductNamed, :name)
      copy(Inventory::StockLevelChanged, :stock_level)
      copy(Pricing::PriceSet, :price)
      copy_nested_to_column(Taxes::VatRateSet, :vat_rate, :code, :vat_rate_code)
    end

    private

    def copy(event, attribute)
      @cqrs.subscribe(-> (event) { copy_event_attribute_to_column(event, attribute, attribute) }, [event])
    end

    def copy_nested_to_column(event, top_event_attribute, nested_attribute, column)
      @cqrs.subscribe(
        -> (event) { copy_nested_event_attribute_to_column(event, top_event_attribute, nested_attribute, column) }, [event])
    end

    def register_product(event)
      Product.create(id: event.data.fetch(:product_id))
    end

    def copy_event_attribute_to_column(event, event_attribute, column)
      product(event).update_attribute(column, event.data.fetch(event_attribute))
    end

    def copy_nested_event_attribute_to_column(event, top_event_attribute, nested_attribute, column)
      product(event).update_attribute(column, event.data.fetch(top_event_attribute).fetch(nested_attribute))
    end

    def product(event)
      find(event.data.fetch(:product_id))
    end

    def find(product_id)
      Product.where(id: product_id).first
    end
  end
end
