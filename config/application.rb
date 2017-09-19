require_relative 'boot'

require 'rails/all'
require 'aggregate_root'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CqrsEsSampleWithRes
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths += Dir["#{config.root}/app/**/"]
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.event_store = RailsEventStore::Client.new
  end

  AggregateRoot.configure do |config|
    config.default_event_store = Rails.application.config.event_store
  end
end
