require_relative "test_helper"

module Ordering
  class NumberGeneratorTest < Test
    def test_includes_year
      assert_includes(NumberGenerator.new.call, "#{Time.now.utc.year}")
    end

    def test_includes_month
      assert_includes(NumberGenerator.new.call, "#{Time.now.utc.month}")
    end
  end
end
