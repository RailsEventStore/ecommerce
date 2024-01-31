module PublicCatalog

  class Configuration
    def call(event_store)
    end
  end

  class Product < ActiveRecord::Base
    self.table_name = 'products'
  end
end