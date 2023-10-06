# frozen_string_literal: true

module Ecommerce
  class Settings < Hanami::Settings
    setting :database_url, constructor: Types::String
  end
end
