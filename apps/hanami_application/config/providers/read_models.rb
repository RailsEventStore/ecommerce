# frozen_string_literal: true

Hanami.app.register_provider :read_models do
  start do
    target.start :event_store
    event_store = target["event_store"]

    catalog = HanamiApplication::ReadModels::Catalog.new(target["relations.products"])
    orders = HanamiApplication::ReadModels::Orders.new(target["relations.orders"], target["relations.order_lines"])

    catalog.subscribe(event_store)
    orders.subscribe(event_store)

    register "read_models.catalog", catalog
    register "read_models.orders", orders
  end
end
