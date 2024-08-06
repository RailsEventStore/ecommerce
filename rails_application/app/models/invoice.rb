class Invoice < ApplicationRecord
  self.table_name = "invoices_tbl"

  belongs_to :order, class_name: "Order", foreign_key: "order_id"

  def issued?
    issued_at.present?
  end

  def address_present?
    address.present?
  end
end
