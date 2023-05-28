command_bus = Rails.configuration.command_bus

[
  ["BigCorp Ltd", "bigcorp", "12345"],
  ["MegaTron Gmbh", "megatron", "qwerty"],
  ["Arkency", 'arkency', 'qwe123']
].each do |name, login, password|
  account_id = SecureRandom.uuid
  customer_id = SecureRandom.uuid
  password_hash = Digest::SHA256.hexdigest(password)

  [
    Crm::RegisterCustomer.new(customer_id: customer_id, name: name),
    Authentication::RegisterAccount.new(account_id: account_id),
    Authentication::SetLogin.new(account_id: account_id, login: login),
    Authentication::SetPasswordHash.new(account_id: account_id, password_hash: password_hash),
    Authentication::ConnectAccountToClient.new(account_id: account_id, client_id: customer_id)
  ].each do |command|
    command_bus.call(command)
  end

end

[
  ["DDDVeteran", 'ddd', 5],
  ["VIP", 'vip', 15],
  ["Addict", 'product_addict', 20]
].each do |coupon|
  command_bus.call(
    Pricing::RegisterCoupon.new(
      coupon_id: SecureRandom.uuid,
      name: coupon[0],
      code: coupon[1],
      discount: coupon[2]
    )
  )
end

[
  ["Fearless Refactoring: Rails controllers", 49],
  ["Rails meets React.js", 49],
  ["Developers Oriented Project Management", 39],
  ["Blogging for busy programmers", 29]
].each do |name_price_tuple|
  product_id = SecureRandom.uuid
  [
    ProductCatalog::RegisterProduct.new(product_id: product_id),
    ProductCatalog::NameProduct.new(product_id: product_id, name: name_price_tuple[0]),
    Pricing::SetPrice.new(product_id: product_id, price: name_price_tuple[1]),
    Taxes::SetVatRate.new(product_id: product_id, vat_rate: Taxes::Configuration.available_vat_rates.first)
  ].each do |command|
    command_bus.call(command)
  end
end
