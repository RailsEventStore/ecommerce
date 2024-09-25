# frozen_string_literal: true

class Product < ApplicationRecord
  self.locking_column = :version
  self.ignored_columns = %w[stock_level]

  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
  validate :validate_vat_rate
  validates :sku, presence: true

  has_one :product_catalog,
          class_name: "Inventory::ProductCatalog",
          foreign_key: :product_id

  default_scope { where(latest: true) }

  def validate_vat_rate
    errors.add(:vat_rate, "is not a number") unless vat_rate.is_a?(Numeric)
  end
end
