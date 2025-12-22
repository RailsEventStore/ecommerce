# frozen_string_literal: true

Hanami.application.register_provider :cqrs do |container|
  prepare do
    require 'infra'

    cqrs = Infra::Cqrs.new(container['event_store'], container['command_bus'])

    register "cqrs", cqrs
  end
end
