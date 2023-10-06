Hanami.app.register_provider :ecommerce, namespace: true do
  prepare do
    require_relative "../../../ecommerce/configuration"
    require_relative "../../../ecommerce/ordering/lib/ordering"

    event_store = target["event_store.client"]
    command_bus = target["command_bus"]

    number_generator = -> { Ordering::NumberGenerator.new }
    payment_gateway = -> { Payments::FakeGateway.new }

    Ecommerce::Configuration.new(
      event_store: event_store,
      command_bus: command_bus,
      number_generator: number_generator,
      payment_gateway: payment_gateway,
      available_vat_rates: [
        Infra::Types::VatRate.new(code: "10", rate: 10),
        Infra::Types::VatRate.new(code: "20", rate: 20)
      ]
    ).call(event_store, command_bus)

    event_store.subscribe(
      target["event_handlers.orders.submit"], to: [Ordering::OrderSubmitted]
    )
  end
end
