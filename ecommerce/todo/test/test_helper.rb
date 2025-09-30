require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/todo"

module Todo
  class Test < Infra::InMemoryTest
    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end

    private

  end
end