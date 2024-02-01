module PublicCatalog

  class Migration
    def change
      ActiveRecord::Base.connection.create_table :public_catalog_products do |t|
        t.string :product_id
        t.string :name
        t.decimal :price

        t.timestamps
      end
    end
  end

  class Product < ActiveRecord::Base
    self.table_name = 'products'
  end

  class Configuration
    def call(event_store)
    end
  end

end