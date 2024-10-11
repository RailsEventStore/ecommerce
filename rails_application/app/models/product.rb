# frozen_string_literal: true

class Product < ApplicationRecord
  self.locking_column = :version

  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
  validate :validate_vat_rate
  validates :sku, presence: true

  default_scope { where(latest: true) }

  before_create :set_stock_level

  def set_stock_level
    self.stock_level = 0
  end

  def validate_vat_rate
    unless vat_rate.is_a?(Numeric)
      errors.add(:vat_rate, "is not a number")
    end
  end
end
