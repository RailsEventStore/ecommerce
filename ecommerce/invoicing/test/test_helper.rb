require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/invoicing"

module Invoicing
  class Test < Infra::InMemoryTest
    cover "Invoicing*"

    def before_setup
      super
      Configuration.new.call(cqrs)
    end
  end
end
