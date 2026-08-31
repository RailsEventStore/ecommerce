# frozen_string_literal: true

Hanami.app.configure_provider :db do
  config.gateway :default do |gateway|
    gateway.database_url = ENV.fetch("DATABASE_URL") { "sqlite://db/hanami_application_#{Hanami.env}.sqlite" }
  end
end
