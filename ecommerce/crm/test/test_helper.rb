require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/crm"

module Crm
  class Test < Infra::InMemoryTest
    def before_setup
      super()
      Configuration.new.call(cqrs)
    end
  end
end
