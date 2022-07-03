require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/authentication"

module Authentication
  class Test < Infra::InMemoryTest
    def before_setup
      super()
      Configuration.new.call(cqrs)
    end
  end
end
