# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

command_bus = Rails.configuration.command_bus

[
  ["BigCorp Ltd", "bigcorp", "12345"],
  ["MegaTron Gmbh", "megatron", "qwerty"],
  ["Arkency", 'arkency', 'qwe123']
].each do |name, login, password|
  account_id = SecureRandom.uuid
  customer_id = SecureRandom.uuid
  password_hash = Digest::SHA256.hexdigest(password)

  command_bus.call(
    Crm::RegisterCustomer.new(customer_id: customer_id, name: name)
  )

  command_bus.call(
    Authentication::RegisterAccount.new(account_id: account_id)
  )

  command_bus.call(
    Authentication::SetLogin.new(account_id: account_id, login: login)
  )

  command_bus.call(
    Authentication::SetPasswordHash.new(account_id: account_id, password_hash: password_hash)
  )

  command_bus.call(
    Authentication::ConnectAccountToClient.new(account_id: account_id, client_id: customer_id)
  )
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
  command_bus.call(
    ProductCatalog::RegisterProduct.new(
      product_id: product_id
    )
  )
  command_bus.call(
    ProductCatalog::NameProduct.new(
      product_id: product_id,
      name: name_price_tuple[0]
    )
  )
  command_bus.call(
    Pricing::SetPrice.new(product_id: product_id, price: name_price_tuple[1])
  )
  command_bus.call(
    Taxes::SetVatRate.new(product_id: product_id, vat_rate: Taxes::Configuration.available_vat_rates.first)
  )
end
