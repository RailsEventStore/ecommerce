# frozen_string_literal: true

require "dry/monads"
require "dry/matcher/result_matcher"

module Ecommerce
  class Operation
    include Dry::Monads[:result, :try]

    class << self
      def inherited(klass)
        klass.include Dry::Monads[:do]
        klass.include Dry::Matcher::ResultMatcher.for(:call)
      end
    end
  end
end
