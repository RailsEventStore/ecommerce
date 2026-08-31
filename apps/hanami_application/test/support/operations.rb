# frozen_string_literal: true

require "dry/monads"

class Hanami::Minitest::Test
  # Provide `Success` and `Failure` for testing operation results.
  include Dry::Monads[:result]
end
