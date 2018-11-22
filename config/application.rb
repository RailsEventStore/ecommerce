require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CqrsEsSampleWithRes
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.paths.add "lib", eager_load: true

    config.to_prepare do
      Rails.configuration.event_store = RailsEventStore::Client.new(
        mapper: RubyEventStore::Mappers::Default.new(serializer: JSON)
      ).tap do |store|
        store.subscribe(Orders::OnOrderSubmitted, to: [OrderSubmitted])
        store.subscribe(Orders::OnOrderExpired, to: [OrderExpired])
        store.subscribe(Orders::OnItemAddedToBasket, to: [ItemAddedToBasket])
        store.subscribe(Orders::OnItemRemovedFromBasket, to: [ItemRemovedFromBasket])
      end

      require 'arkency/command_bus'
      command_bus = Arkency::CommandBus.new.tap do |bus|
        bus.register(SubmitOrder, OnSubmitOrder.new(number_generator: Rails.configuration.number_generator))
        bus.register(SetOrderAsExpired, OnSetOrderAsExpired.new)
        bus.register(AddItemToBasket, OnAddItemToBasket.new)
        bus.register(RemoveItemFromBasket, OnRemoveItemFromBasket.new)
      end
      Rails.configuration.command_bus = ->(command) do
        command.validate!
        command_bus.(command)
      end
    end
  end
end
