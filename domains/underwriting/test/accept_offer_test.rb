require_relative "test_helper"

module Underwriting
  class AcceptOfferTest < Test
    cover "Underwriting*"

    def test_offer_can_be_accepted_after_premium_calculation
      application_id = SecureRandom.uuid
      submit_application(application_id, BigDecimal("1000"))
      evaluate_risk(application_id, "standard")
      calculate_premium(application_id)

      assert_events(
        stream(application_id),
        OfferAccepted.new(data: { application_id: application_id, premium: BigDecimal("50") })
      ) { accept_offer(application_id) }
    end

    def test_offer_can_not_be_accepted_before_premium_calculation
      application_id = SecureRandom.uuid
      submit_application(application_id)
      evaluate_risk(application_id)

      assert_raises(InsuranceApplication::InvalidState) do
        accept_offer(application_id)
      end
    end

    def test_offer_can_not_be_accepted_twice
      application_id = SecureRandom.uuid
      submit_application(application_id)
      evaluate_risk(application_id)
      calculate_premium(application_id)
      accept_offer(application_id)

      assert_raises(InsuranceApplication::InvalidState) do
        accept_offer(application_id)
      end
    end
  end
end
