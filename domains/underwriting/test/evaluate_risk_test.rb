require_relative "test_helper"

module Underwriting
  class EvaluateRiskTest < Test
    cover "Underwriting*"

    def test_risk_can_be_evaluated_for_submitted_application
      application_id = SecureRandom.uuid
      submit_application(application_id)

      assert_events(
        stream(application_id),
        RiskEvaluated.new(data: { application_id: application_id, risk_class: "high" })
      ) { evaluate_risk(application_id, "high") }
    end

    def test_risk_can_not_be_evaluated_before_submission
      application_id = SecureRandom.uuid

      assert_raises(InsuranceApplication::InvalidState) do
        evaluate_risk(application_id)
      end
    end

    def test_risk_can_not_be_evaluated_twice
      application_id = SecureRandom.uuid
      submit_application(application_id)
      evaluate_risk(application_id)

      assert_raises(InsuranceApplication::InvalidState) do
        evaluate_risk(application_id)
      end
    end

    def test_risk_class_must_be_known
      application_id = SecureRandom.uuid
      submit_application(application_id)

      assert_raises(Infra::Command::Invalid) do
        evaluate_risk(application_id, "extreme")
      end
    end
  end
end
