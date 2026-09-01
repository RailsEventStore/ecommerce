require_relative "test_helper"

module Underwriting
  class CalculatePremiumTest < Test
    cover "Underwriting*"

    def test_premium_for_low_risk
      application_id = SecureRandom.uuid
      submit_application(application_id, BigDecimal("1000"))
      evaluate_risk(application_id, "low")

      assert_events(
        stream(application_id),
        PremiumCalculated.new(data: { application_id: application_id, premium: BigDecimal("20") })
      ) { calculate_premium(application_id) }
    end

    def test_premium_for_standard_risk
      application_id = SecureRandom.uuid
      submit_application(application_id, BigDecimal("1000"))
      evaluate_risk(application_id, "standard")

      assert_events(
        stream(application_id),
        PremiumCalculated.new(data: { application_id: application_id, premium: BigDecimal("50") })
      ) { calculate_premium(application_id) }
    end

    def test_premium_for_high_risk
      application_id = SecureRandom.uuid
      submit_application(application_id, BigDecimal("2000"))
      evaluate_risk(application_id, "high")

      assert_events(
        stream(application_id),
        PremiumCalculated.new(data: { application_id: application_id, premium: BigDecimal("200") })
      ) { calculate_premium(application_id) }
    end

    def test_premium_can_not_be_calculated_before_risk_evaluation
      application_id = SecureRandom.uuid
      submit_application(application_id)

      assert_raises(InsuranceApplication::InvalidState) do
        calculate_premium(application_id)
      end
    end

    def test_premium_can_not_be_calculated_twice
      application_id = SecureRandom.uuid
      submit_application(application_id)
      evaluate_risk(application_id)
      calculate_premium(application_id)

      assert_raises(InsuranceApplication::InvalidState) do
        calculate_premium(application_id)
      end
    end
  end
end
