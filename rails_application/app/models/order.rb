class Order < ApplicationRecord
  has_many :order_items
  has_one :invoice

  def state
    self.status
  end

  def customer
    Customer.find(customer_id) if customer_id
  end

  def submitted?
    status == "Submitted"
  end

  def invoice_issued?
    invoice_issued
  end

  def shipment_full_address
    "#{address}, #{city}, #{country} #{addressed_to}"
  end

  def billing_address_specified?
    invoice_tax_id_number.present? &&
      invoice_country.present? &&
      invoice_address.present? &&
      invoice_city.present? &&
      invoice_addressed_to.present? &&
      invoice_address.present?
  end
end
