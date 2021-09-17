class ProductRepository
  class Record < ApplicationRecord
    self.table_name = "products"
  end

  def upsert(product)
    Record.upsert(product.to_h)
    nil
  end

  def find(product_id)
    Record.where(id: product_id).map(&method(:wrap_record)).first
  end

  def find_or_initialize_by_id(id)
    find(id) || ::ProductCatalog::Product.new(id: id)
  end

  def all
    Record.all.map(&method(:wrap_record))
  end

  private

  def wrap_record(r)
    ::ProductCatalog::Product.new(**r.attributes.symbolize_keys)
  end
end
