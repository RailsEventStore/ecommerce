require "test_helper"

module Applications
  class ApplicationsTest < InMemoryRESTestCase
    cover "Applications*"

    def configure(event_store, _command_bus)
      Applications::Configuration.new.call(event_store)
    end

    def test_application_submitted
      submit_application(application_id, BigDecimal("1000"))
      submit_application(other_application_id, BigDecimal("2000"))

      assert_equal(2, Applications.all.count)
      assert_equal([other_application_id, application_id], Applications.all.map(&:application_id))
      application = Applications.all.find_by!(application_id: application_id)
      assert_equal(BigDecimal("1000"), application.coverage_amount)
      assert_equal("submitted", application.state)
    end

    def test_risk_evaluated
      submit_application(application_id, BigDecimal("1000"))
      submit_application(other_application_id, BigDecimal("2000"))
      evaluate_risk(application_id, "high")

      application = Applications.all.find_by!(application_id: application_id)
      assert_equal("high", application.risk_class)
      assert_equal("risk evaluated", application.state)
      other = Applications.all.find_by!(application_id: other_application_id)
      assert_nil(other.risk_class)
      assert_equal("submitted", other.state)
    end

    def test_premium_calculated
      submit_application(application_id, BigDecimal("1000"))
      submit_application(other_application_id, BigDecimal("2000"))
      evaluate_risk(application_id, "low")
      calculate_premium(application_id, BigDecimal("20"))

      application = Applications.all.find_by!(application_id: application_id)
      assert_equal(BigDecimal("20"), application.premium)
      assert_equal("priced", application.state)
      assert_nil(Applications.all.find_by!(application_id: other_application_id).premium)
    end

    def test_offer_accepted
      submit_application(application_id, BigDecimal("1000"))
      submit_application(other_application_id, BigDecimal("2000"))
      evaluate_risk(application_id, "low")
      calculate_premium(application_id, BigDecimal("20"))
      accept_offer(application_id, BigDecimal("20"))

      assert_equal("accepted", Applications.all.find_by!(application_id: application_id).state)
      assert_equal("submitted", Applications.all.find_by!(application_id: other_application_id).state)
    end

    private

    def application_id
      @application_id ||= SecureRandom.uuid
    end

    def other_application_id
      @other_application_id ||= SecureRandom.uuid
    end

    def submit_application(id, coverage_amount)
      event_store.publish(
        Underwriting::ApplicationSubmitted.new(data: { application_id: id, coverage_amount: coverage_amount })
      )
    end

    def evaluate_risk(id, risk_class)
      event_store.publish(
        Underwriting::RiskEvaluated.new(data: { application_id: id, risk_class: risk_class })
      )
    end

    def calculate_premium(id, premium)
      event_store.publish(
        Underwriting::PremiumCalculated.new(data: { application_id: id, premium: premium })
      )
    end

    def accept_offer(id, premium)
      event_store.publish(
        Underwriting::OfferAccepted.new(data: { application_id: id, premium: premium })
      )
    end
  end
end
