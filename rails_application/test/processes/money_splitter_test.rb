require "test_helper"

module Processes
  class MoneySplitterTest < Minitest::Test
    cover "Processes::MoneySplitter"

    def test_splitting_money_without_losing_cents
      assert_equal([0.01, 0.01, 0.01], MoneySplitter.new(0.03, 3).call)
      assert_equal([0.01, 0.02], MoneySplitter.new(0.03, 2).call.sort)
      assert_equal([0, 0, 0.01, 0.01, 0.01], MoneySplitter.new(0.03, 5).call.sort)
    end
  end
end