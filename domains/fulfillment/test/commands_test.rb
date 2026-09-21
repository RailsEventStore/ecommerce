require_relative "test_helper"

module Fulfillment
  class CommandsTest < Test
    cover "Fulfillment*"

    ORDER_ID = "123e4567-e89b-42d3-a456-426614174000"
    COMMANDS = [CancelOrder, ConfirmOrder, RegisterOrder].freeze

    def test_exposes_order_id
      COMMANDS.each do |command|
        assert_equal(ORDER_ID, command.new(ORDER_ID).order_id)
        assert_equal(ORDER_ID, command.new(ORDER_ID).aggregate_id)
      end
    end

    def test_rejects_invalid_order_id
      COMMANDS.each do |command|
        assert_raises(Infra::Command::Invalid) do
          command.new("not-a-uuid")
        end

        assert_raises(Infra::Command::Invalid) do
          command.new(Object.new)
        end

        assert_raises(Infra::Command::Invalid) do
          command.new("123e4567-e89b-12d3-a456-426614174000")
        end

        assert_raises(Infra::Command::Invalid) do
          command.new("123e4567-e89b-42d3-7456-426614174000")
        end
      end
    end
  end
end
