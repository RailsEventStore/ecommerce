# frozen_string_literal: true

require "hanami"

module Ecommerce
  class Application < Hanami::Application
    config.sessions = :cookie, {
      key: "ecommerce.session",
      secret: settings.session_secret,
      expire_after: 60 * 60 * 24 * 365 # 1 year
    }
  end
end
