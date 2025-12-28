class RegisterProduct
  def call(name, price)
    product_id = SecureRandom.uuid
    command_bus.(ProductCatalog::RegisterProduct.new(product_id: product_id))
    command_bus.(ProductCatalog::NameProduct.new(product_id: product_id, name: name))
    command_bus.(Pricing::SetPrice.new(product_id: product_id, price: price))
  end

  private

  def command_bus
    Rails.configuration.command_bus
  end
end