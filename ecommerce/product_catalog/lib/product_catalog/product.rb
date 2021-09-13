module ProductCatalog
  class Product < ActiveRecord::Base
    AlreadyRegistered = Class.new(StandardError)

    self.table_name = "products"

    def register(name)
      raise AlreadyRegistered unless new_record?
      self.name = name
    end
  end
end