# frozen_string_literal: true

module HanamiApplication
  class Settings < Hanami::Settings
    setting :session_secret,
            default: "insecure-development-only-secret-0123456789abcdef0123456789abcdef",
            constructor: Types::String.constrained(min_size: 64)
  end
end
