require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/authentication"

module Authentication
  class Test < Infra::InMemoryTest
    def before_setup
      super()
      Configuration.new.call(cqrs)
    end

    private

    def fake_login
      "fake_login"
    end
  end
end
