# frozen_string_literal: true

class Product < ApplicationRecord
  self.ignored_columns = %w[stock_level]

  validates :name, presence: true
  validates :price, numericality: { greater_than: 0 }
  validate :validate_vat_rate
  validates :sku, presence: true

  has_one :product_catalog, class_name: "Inventory::ProductCatalog", foreign_key: :product_id

  default_scope { where(latest: true) }

  def validate_vat_rate
    unless vat_rate.is_a?(Numeric)
      errors.add(:vat_rate, "is not a number")
    end
  end

  def change_name(new_name)
    return if new_name == self.name || new_name.blank?
    self.name = new_name
    self.save!
  end

  def change_price!(params)
    if params["future_price"].present?
      self.future_price = params["future_price"]["price"]
      self.future_price_start_time = params["future_price"]["start_time"]
      self.save!
    else
      ApplicationRecord.transaction do
        product_with_new_price = self.dup
        product_with_new_price.price = params[:price]
        product_with_new_price.latest = true
        self.latest = false
        product_with_new_price.save!
        self.save!
      end
    end
  end
end
