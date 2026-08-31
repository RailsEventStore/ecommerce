# frozen_string_literal: true

Hanami.app.register_provider :read_models do
  start do
    target.start :event_store
    event_store = target["event_store"]

    catalog = HanamiApplication::ReadModels::Catalog.new
    orders = HanamiApplication::ReadModels::Orders.new

    event_store.read.each do |event|
      catalog.apply(event)
      orders.apply(event)
    end

    catalog.subscribe(event_store)
    orders.subscribe(event_store)

    register "read_models.catalog", catalog
    register "read_models.orders", orders
  end
end
