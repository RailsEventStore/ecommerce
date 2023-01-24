require_relative "test_helper"

module Processes
  class MoneySplitterTest < Minitest::Test
    cover "Processes::MoneySplitter"

    def test_splitting_money_without_losing_cents
      assert_equal([0.01, 0.01, 0.01], MoneySplitter.new(0.03, [1, 1, 1]).call)
      assert_equal([0.01, 0.02], MoneySplitter.new(0.03, [1, 1]).call.sort)
      assert_equal([0, 0, 0.01, 0.01, 0.01], MoneySplitter.new(0.03, [1, 1, 1, 1, 1]).call.sort)
      assert_equal([0, 0, 0.03], MoneySplitter.new(0.03, [1, 0, 0]).call.sort)

      assert_raises(ArgumentError) { MoneySplitter.new(0.03, nil).call }
      assert_raises(ArgumentError) { MoneySplitter.new(0.03, 'not nil nor array').call }
      assert_raises(ArgumentError) { MoneySplitter.new(0.03, []).call }
    end
  end
end