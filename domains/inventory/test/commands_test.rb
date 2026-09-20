require_relative "test_helper"

module Inventory
  class CommandsTest < Test
    COMMANDS = [Dispatch, Release, Reserve, Supply].freeze
    PRODUCT_ID = "123e4567-e89b-42d3-a456-426614174000"

    def test_coerces_quantity
      COMMANDS.each do |command|
        assert_equal(2, command.new(PRODUCT_ID, "2").quantity)
      end
    end

    def test_rejects_invalid_product_id
      COMMANDS.each do |command|
        assert_raises(Infra::Command::Invalid) do
          command.new("not-a-uuid", 2)
        end

        assert_raises(Infra::Command::Invalid) do
          command.new(Object.new, 2)
        end
      end
    end

    def test_rejects_uuid_with_wrong_version
      COMMANDS.each do |command|
        assert_raises(Infra::Command::Invalid) do
          command.new("123e4567-e89b-12d3-a456-426614174000", 2)
        end
      end
    end

    def test_rejects_uuid_with_wrong_variant
      COMMANDS.each do |command|
        assert_raises(Infra::Command::Invalid) do
          command.new("123e4567-e89b-42d3-7456-426614174000", 2)
        end
      end
    end

    def test_rejects_non_positive_quantity
      COMMANDS.each do |command|
        assert_raises(Infra::Command::Invalid) do
          command.new(PRODUCT_ID, 0)
        end
      end
    end

    def test_rejects_invalid_quantity
      COMMANDS.each do |command|
        assert_raises(Infra::Command::Invalid) do
          command.new(PRODUCT_ID, "two")
        end

        assert_raises(Infra::Command::Invalid) do
          command.new(PRODUCT_ID, Object.new)
        end
      end
    end
  end
end
