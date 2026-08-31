# frozen_string_literal: true

Hanami.app.register_provider :seeds do
  start do
    target.start :command_bus
    target.start :read_models

    command_bus = target["command_bus"]

    {
      "Fearless Refactoring: Rails Controllers" => 49,
      "Domain-Driven Rails" => 69,
      "Rails meets React.js" => 49,
      "Developers Oriented Project Management" => 39,
      "Blogging for Busy Programmers" => 29
    }.each do |name, price|
      product_id = SecureRandom.uuid
      command_bus.call(ProductCatalog::RegisterProduct.new(product_id: product_id))
      command_bus.call(ProductCatalog::NameProduct.new(product_id: product_id, name: name))
      command_bus.call(Pricing::SetPrice.new(product_id: product_id, price: price))
    end
  end
end
