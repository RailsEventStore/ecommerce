# frozen_string_literal: true

class Product < ApplicationRecord
  before_create :set_stock_level

  def set_stock_level
    self.stock_level = 0
  end
end
