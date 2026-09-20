require_relative "test_helper"

module Policies
  class CommandsTest < Test
    cover "Policies*"

    POLICY_ID = "123e4567-e89b-42d3-a456-426614174000"

    def test_coerces_premium
      assert_equal(BigDecimal("50"), IssuePolicy.new(POLICY_ID, "50").premium)
      assert_equal(BigDecimal("2.1"), IssuePolicy.new(POLICY_ID, 2.1).premium)
    end

    def test_accepts_zero_premium
      assert_equal(BigDecimal("0"), IssuePolicy.new(POLICY_ID, 0).premium)
    end

    def test_rejects_negative_premium
      assert_raises(Infra::Command::Invalid) do
        IssuePolicy.new(POLICY_ID, -1)
      end
    end

    def test_rejects_invalid_premium
      assert_raises(Infra::Command::Invalid) do
        IssuePolicy.new(POLICY_ID, Object.new)
      end
    end

    def test_rejects_invalid_policy_id
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) do
          constructor.call("not-a-uuid")
        end

        assert_raises(Infra::Command::Invalid) do
          constructor.call(Object.new)
        end
      end
    end

    def test_rejects_uuid_with_wrong_version
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) do
          constructor.call("123e4567-e89b-12d3-a456-426614174000")
        end
      end
    end

    def test_rejects_uuid_with_wrong_variant
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) do
          constructor.call("123e4567-e89b-42d3-7456-426614174000")
        end
      end
    end

    private

    def constructors
      [
        ->(policy_id) { IssuePolicy.new(policy_id, 50) },
        ->(policy_id) { PutPolicyInForce.new(policy_id) },
        ->(policy_id) { TerminatePolicy.new(policy_id) }
      ]
    end
  end
end
