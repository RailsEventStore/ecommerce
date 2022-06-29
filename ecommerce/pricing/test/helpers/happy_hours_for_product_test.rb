require_relative "../test_helper"

module Pricing
  module Helpers
    class HappyHoursForProductTest < Test
      cover "Pricing::Helpers::HappyHoursForProduct*"

      def test_returns_discount_for_specific_hour
        some_product_id = SecureRandom.uuid
        run_command(
          Pricing::CreateHappyHour.new(
            details: {
              id: SecureRandom.uuid,
              name: "Night Owls",
              code: "owls",
              discount: "25",
              start_hour: "20",
              end_hour: "2",
              product_ids: [some_product_id]
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
              end_hour: "18",
              product_ids: [some_product_id]
            }
          )
        )

        helper_instance = Pricing::Helpers::HappyHoursForProduct.new(cqrs.event_store)

        assert helper_instance.discount_for(some_product_id, 21) == 25
        assert helper_instance.discount_for(some_product_id, 19).nil?
        assert helper_instance.discount_for(some_product_id, 17) == 15
      end

      private

      def create_happy_hour(**kwargs)
        run_command(
          CreateHappyHour.new(kwargs)
        )
      end


    end
  end
end
