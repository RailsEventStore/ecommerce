# frozen_string_literal: true

Hanami.application.register_provider :persistence, namespace: true do
  prepare do
    require "rom-changeset"
    require "rom/core"
    require "rom/sql"
    require "ruby_event_store/rom"

    rom_config = ROM::Configuration.new(:sql, target["settings"].database_url)

    rom_config.plugin(:sql, relations: :instrumentation) do |plugin_config|
      plugin_config.notifications = target["notifications"]
    end

    rom_config.plugin(:sql, relations: :auto_restrictions)

    register "config", rom_config
    register "db", rom_config.gateways[:default].connection
  end

  start do
    config = target["persistence.config"]
    config.auto_registration target.root.join("lib/ecommerce/persistence")

    config.register_mapper   RubyEventStore::ROM::Mappers::StreamEntryToSerializedRecord
    config.register_mapper   RubyEventStore::ROM::Mappers::EventToSerializedRecord
    config.register_relation RubyEventStore::ROM::Relations::Events
    config.register_relation RubyEventStore::ROM::Relations::StreamEntries

    register "rom", ROM.container(config)
  end
end
