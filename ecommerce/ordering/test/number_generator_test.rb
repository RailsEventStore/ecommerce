require_relative 'test_helper'

module Ordering
  class NumberGeneratorTest < Ecommerce::InMemoryTestCase
    def test_includes_year
      assert_includes(NumberGenerator.new.call, "#{Time.current.year}")
    end

    def test_includes_month
      assert_includes(NumberGenerator.new.call, "#{Time.current.month}")
    end
  end
end