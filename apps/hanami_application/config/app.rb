# frozen_string_literal: true

require "hanami"

module HanamiApplication
  class App < Hanami::App
    config.actions.sessions = :cookie, {
      key: "hanami_application.session",
      secret: settings.session_secret,
      expire_after: 60 * 60 * 24 * 30
    }
  end
end
