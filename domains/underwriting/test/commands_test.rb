require_relative "test_helper"

module Underwriting
  class CommandsTest < Test
    cover "Underwriting*"

    APPLICATION_ID = "123e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      command = EvaluateRisk.new(APPLICATION_ID, "standard")
      assert_equal(APPLICATION_ID, command.application_id)
      assert_equal(APPLICATION_ID, command.aggregate_id)
      assert_equal("standard", command.risk_class)
    end

    def test_coerces_coverage_amount
      assert_equal(BigDecimal("1000"), SubmitApplication.new(APPLICATION_ID, "1000").coverage_amount)
      assert_equal(BigDecimal("2.1"), SubmitApplication.new(APPLICATION_ID, 2.1).coverage_amount)
      assert_equal(BigDecimal("0"), SubmitApplication.new(APPLICATION_ID, 0).coverage_amount)
    end

    def test_rejects_invalid_application_id
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_rejects_invalid_risk_class
      assert_raises(Infra::Command::Invalid) { EvaluateRisk.new(APPLICATION_ID, "extreme") }
      assert_raises(Infra::Command::Invalid) { EvaluateRisk.new(APPLICATION_ID, Object.new) }
    end

    def test_rejects_invalid_coverage_amount
      assert_raises(Infra::Command::Invalid) { SubmitApplication.new(APPLICATION_ID, -1) }
      assert_raises(Infra::Command::Invalid) { SubmitApplication.new(APPLICATION_ID, Object.new) }
    end

    private

    def constructors
      [
        ->(id) { SubmitApplication.new(id, 1000) },
        ->(id) { EvaluateRisk.new(id, "low") },
        ->(id) { CalculatePremium.new(id) },
        ->(id) { AcceptOffer.new(id) }
      ]
    end
  end
end
