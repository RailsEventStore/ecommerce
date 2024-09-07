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

  def total_after_discount
    total - ((total * discount) / 100)
  end

  def add_item(product)
    if order_items.any? { |order_item| order_item.product_id == product.id }
      order_items.find_by(product_id: product.id).increment!(:quantity)
    else
      order_items.create!(product_id: product.id, quantity: 1)
    end
    self.total += product.price
  end

  def remove_item(product)
    order_item = order_items.find_by(product_id: product.id)
    if order_item && order_item.quantity > 0
      order_items.find_by(product_id: product.id).decrement!(:quantity)
      self.total -= product.price
    end
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
