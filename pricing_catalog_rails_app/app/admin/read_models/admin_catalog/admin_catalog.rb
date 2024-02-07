module AdminCatalog

  class Migration
    def change
      ActiveRecord::Base.connection.create_table :admin_catalog_products do |t|
        t.string :product_id
        t.string :name
        t.decimal :price

        t.timestamps
      end
    end
  end

  class Product < ActiveRecord::Base
    self.table_name = 'admin_catalog_products'
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(
        -> (event) {Product.create(product_id: event.data[:product_id])},
        to: [ProductCatalog::ProductRegistered])
      event_store.subscribe(
        -> (event) {Product.find_by(product_id: event.data[:product_id]).update(name: event.data[:name])},
        to: [ProductCatalog::ProductNamed])
      event_store.subscribe(
        -> (event) {Product.find_by(product_id: event.data[:product_id]).update(price: event.data[:price])},
        to: [Pricing::PriceSet])
    end

    private

  end

end