require_relative 'test_helper'

module ProductCatalog
  class FakeNameModerationTest < Test
    cover "ProductCatalog*"

    def test_allows_ordinary_name
      assert FakeNameModeration.new.allowed?("Async Remote")
    end

    def test_does_not_allow_cursed_name
      refute FakeNameModeration.new.allowed?("Curse word")
    end

    def test_does_not_allow_cursed_name_regardless_of_case
      refute FakeNameModeration.new.allowed?("CURSE word")
    end
  end
end
