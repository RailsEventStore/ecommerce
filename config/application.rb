require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CqrsEsSampleWithRes
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.to_prepare do
      Rails.configuration.event_store = RailsEventStore::Client.new(
        mapper: RubyEventStore::Mappers::Default.new(serializer: JSON)
      ).tap do |es|
        es.subscribe(Denormalizers::OrderSubmitted, to: [Events::OrderSubmitted])
        es.subscribe(Denormalizers::OrderExpired, to: [Events::OrderExpired])
        es.subscribe(Denormalizers::ItemAddedToBasket, to: [Events::ItemAddedToBasket])
        es.subscribe(Denormalizers::ItemRemovedFromBasket, to: [Events::ItemRemovedFromBasket])
      end
    end
  end
end
