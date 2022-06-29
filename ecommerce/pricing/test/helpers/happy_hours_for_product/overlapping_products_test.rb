require_relative "../../test_helper"

module Pricing
  module Helpers
    class OverlappingProductsTest < Test
      cover "Pricing::Helpers::HappyHoursForProduct#products_with_overlapping_happy_hours"

      def setup
        @helper = Pricing::Helpers::HappyHoursForProduct.new(cqrs.event_store)

        @first_product_id = SecureRandom.uuid
        @second_product_id = SecureRandom.uuid
        @third_product_id = SecureRandom.uuid
        @fourth_product_id = SecureRandom.uuid
        @fifth_product_id = SecureRandom.uuid

        run_command(
          Pricing::CreateHappyHour.new(
            details: {
              id: SecureRandom.uuid,
              name: "Night Owls",
              code: "owls",
              discount: "25",
              start_hour: "20",
              end_hour: "2",
              product_ids: [@first_product_id, @third_product_id]
            }
          )
        )
        run_command(
          Pricing::CreateHappyHour.new(
            details: {
              id: SecureRandom.uuid,
              name: "Tea Time",
              code: "tea",
              discount: "15",
              start_hour: "17",
              end_hour: "19",
              product_ids: [@second_product_id]
            }
          )
        )
        run_command(
          Pricing::CreateHappyHour.new(
            details: {
              id: SecureRandom.uuid,
              name: "High Noon",
              code: "high_noon",
              discount: "50",
              start_hour: "12",
              end_hour: "13",
              product_ids: [@fourth_product_id]
            }
          )
        )
        run_command(
          Pricing::CreateHappyHour.new(
            details: {
              id: SecureRandom.uuid,
              name: "Drrracula",
              code: "dracula",
              discount: "33",
              start_hour: "0",
              end_hour: "1",
              product_ids: [@fifth_product_id]
            }
          )
        )

        @products = [@first_product_id, @second_product_id, @third_product_id, @fourth_product_id, @fifth_product_id]
      end

      def test_returns_products_with_overlapping_happy_hours
        result = @helper.products_with_overlapping_happy_hours(@products, 18, 22).sort
        assert result == [@first_product_id, @second_product_id, @third_product_id].sort

        result = @helper.products_with_overlapping_happy_hours(@products, 17, 18)
        assert result == [@second_product_id]
      end

      def test_handles_case_when_end_hour_before_start_hour
        result = @helper.products_with_overlapping_happy_hours(@products, 23, 5).sort
        assert result == [@first_product_id, @third_product_id, @fifth_product_id].sort

        result = @helper.products_with_overlapping_happy_hours(@products, 23, 0).sort
        assert result == [@first_product_id, @third_product_id].sort

        result = @helper.products_with_overlapping_happy_hours(@products, 23, 1).sort
        assert result == [@first_product_id, @third_product_id, @fifth_product_id].sort
      end

      def test_returns_empty_array_for_hour_not_covered
        result = @helper.products_with_overlapping_happy_hours(@products, 19, 20)
        assert result == []
      end

      def test_covers_whole_day_for_same_start_and_end
        result = @helper.products_with_overlapping_happy_hours(@products, 17, 17).sort
        assert result == @products.sort
      end

      def test_raises_error_for_invalid_hours
        result = -> { @helper.products_with_overlapping_happy_hours(@products, 36, 35) }
        assert_raises(Dry::Types::ConstraintError) do
          result.call
        end

        result = -> { @helper.products_with_overlapping_happy_hours(@products, -2, -2) }
        assert_raises(Dry::Types::ConstraintError) do
          result.call
        end
      end
    end
  end
end
