command_bus = Rails.configuration.command_bus

store_1_id = SecureRandom.uuid
command_bus.call(Stores::RegisterStore.new(store_1_id))
command_bus.call(Stores::NameStore.new(store_1_id, Stores::StoreName.new(value: "Bookstore")))

store_2_id = SecureRandom.uuid
command_bus.call(Stores::RegisterStore.new(store_2_id))
command_bus.call(Stores::NameStore.new(store_2_id, Stores::StoreName.new(value: "E-Learning Platform")))

[
  ["BigCorp Ltd", "bigcorp", "12345", store_1_id],
  ["MegaTron Gmbh", "megatron", "qwerty", store_1_id],
  ["Arkency", 'arkency', 'qwe123', store_2_id]
].each do |name, login, password, store_id|
  account_id = SecureRandom.uuid
  customer_id = SecureRandom.uuid
  password_hash = Digest::SHA256.hexdigest(password)

  [
    Crm::RegisterCustomer.new(customer_id: customer_id, name: name),
    Stores::RegisterCustomer.new(store_id, customer_id),
    Authentication::RegisterAccount.new(account_id),
    Authentication::ConnectAccountToClient.new(account_id, customer_id),
    Authentication::SetLogin.new(account_id, login),
    Authentication::SetPasswordHash.new(account_id, password_hash)
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
  ["20", 20],
  ["10", 10]
].each do |vat_rate|
  vat_rate_id = SecureRandom.uuid
  command_bus.call(
    Taxes::AddAvailableVatRate.new(
      vat_rate_id,
      Infra::Types::VatRate.new(code: vat_rate[0], rate: vat_rate[1])
    )
  )
  command_bus.call(
    Stores::RegisterVatRate.new(store_1_id, vat_rate_id)
  )
end

[
  ["Fearless Refactoring: Rails controllers", 49, store_1_id],
  ["Rails meets React.js", 49, store_1_id],
  ["Domain-Driven Rails", 39, store_1_id],
  ["Async Remote", 39, store_2_id],
  ["Developers Oriented Project Management", 39, store_2_id],
  ["Blogging for busy programmers", 29, store_2_id]
].each do |name, price, store_id|
  product_id = SecureRandom.uuid
  [
    ProductCatalog::RegisterProduct.new(product_id),
    ProductCatalog::NameProduct.new(product_id, name),
    Pricing::SetPrice.new(product_id: product_id, price: price),
    Taxes::SetVatRate.new(product_id, "20"),
    Stores::RegisterProduct.new(store_id, product_id)
  ].each do |command|
    command_bus.call(command)
  end
end
