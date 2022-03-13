# frozen_string_literal: true

Hanami.application.register_provider :cqrs do |container|
  prepare do
    require 'infra'

    cqrs = Infra::Cqrs.new(container['event_store'], container['command_bus'])

    register "cqrs", cqrs
  end

  start do
    require_relative "../../../ecommerce/configuration"

    Ecommerce::Configuration.new(
      number_generator: -> { Ordering::NumberGenerator.new },
      payment_gateway: -> { @gateway ||= Payments::FakeGateway.new },
      available_vat_rates: [
        Infra::Types::VatRate.new(code: "10", rate: 10),
        Infra::Types::VatRate.new(code: "20", rate: 20)
      ]
    ).call(container['cqrs'])
  end
end
