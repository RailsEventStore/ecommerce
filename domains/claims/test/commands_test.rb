require_relative "test_helper"

module Claims
  class CommandsTest < Test
    cover "Claims*"

    CLAIM_ID = "123e4567-e89b-42d3-a456-426614174000"
    POLICY_ID = "223e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      report = ReportLoss.new(CLAIM_ID, POLICY_ID, "Flooded kitchen")

      assert_equal(CLAIM_ID, report.claim_id)
      assert_equal(POLICY_ID, report.policy_id)
      assert_equal("Flooded kitchen", report.description)
      assert_equal(CLAIM_ID, report.aggregate_id)
      assert_equal(CLAIM_ID, SettleClaim.new(CLAIM_ID).claim_id)
    end

    def test_coerces_assessed_amount
      assert_equal(BigDecimal("300"), AssessLoss.new(CLAIM_ID, "300").amount)
      assert_equal(BigDecimal("2.1"), AssessLoss.new(CLAIM_ID, 2.1).amount)
      assert_equal(BigDecimal("0"), AssessLoss.new(CLAIM_ID, 0).amount)
    end

    def test_rejects_invalid_claim_id
      claim_id_constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_rejects_invalid_policy_id
      assert_raises(Infra::Command::Invalid) do
        ReportLoss.new(CLAIM_ID, "not-a-uuid", "Flooded kitchen")
      end
    end

    def test_rejects_invalid_description
      assert_raises(Infra::Command::Invalid) do
        ReportLoss.new(CLAIM_ID, POLICY_ID, Object.new)
      end
    end

    def test_accepts_description_string_subclass
      description = Class.new(String).new("Flooded kitchen")

      assert_equal(description, ReportLoss.new(CLAIM_ID, POLICY_ID, description).description)
    end

    def test_rejects_invalid_assessed_amount
      assert_raises(Infra::Command::Invalid) { AssessLoss.new(CLAIM_ID, -1) }
      assert_raises(Infra::Command::Invalid) { AssessLoss.new(CLAIM_ID, Object.new) }
    end

    private

    def claim_id_constructors
      [
        ->(claim_id) { ReportLoss.new(claim_id, POLICY_ID, "Flooded kitchen") },
        ->(claim_id) { AssessLoss.new(claim_id, 300) },
        ->(claim_id) { SettleClaim.new(claim_id) }
      ]
    end
  end
end
