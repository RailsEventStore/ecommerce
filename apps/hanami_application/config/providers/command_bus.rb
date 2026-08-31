# frozen_string_literal: true

Hanami.app.register_provider :command_bus do
  start do
    target.start :event_store

    command_bus = Infra::CommandBus.new
    [
      ProductCatalog::Configuration.new,
      Pricing::Configuration.new,
      Fulfillment::Configuration.new(-> { Fulfillment::NumberGenerator.new })
    ].each { |configuration| configuration.call(target["event_store"], command_bus) }

    register "command_bus", command_bus
  end
end
