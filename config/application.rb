require_relative 'boot'

require 'rails/all'
require 'arkency/command_bus'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CqrsEsSampleWithRes
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.paths.add "lib", eager_load: true

    config.to_prepare do
      Rails.configuration.event_store = RailsEventStore::Client.new(
        mapper: RubyEventStore::Mappers::Default.new(serializer: JSON)
      ).tap do |es|
        es.subscribe(Denormalizers::OrderSubmitted, to: [Events::OrderSubmitted])
        es.subscribe(Denormalizers::OrderExpired, to: [Events::OrderExpired])
        es.subscribe(Denormalizers::ItemAddedToBasket, to: [Events::ItemAddedToBasket])
        es.subscribe(Denormalizers::ItemRemovedFromBasket, to: [Events::ItemRemovedFromBasket])
      end

      Rails.configuration.command_bus = Arkency::CommandBus.new.tap do |bus|
        register = bus.method(:register)
        { Command::SubmitOrder => CommandHandlers::SubmitOrder.new(
          number_generator: Domain::Services::NumberGenerator.new),
          Command::SetOrderAsExpired => CommandHandlers::SetOrderAsExpired.new,
          Command::AddItemToBasket => CommandHandlers::AddItemToBasket.new,
          Command::RemoveItemFromBasket => CommandHandlers::RemoveItemFromBasket.new,
        }.map(&register)
      end
    end
  end
end
