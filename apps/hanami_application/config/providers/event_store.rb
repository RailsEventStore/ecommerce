# frozen_string_literal: true

Hanami.app.register_provider :event_store do
  prepare do
    require "ecommerce"
  end

  start do
    register "event_store", Infra::EventStore.in_memory
  end
end
