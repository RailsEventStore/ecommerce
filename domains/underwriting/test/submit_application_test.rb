require_relative "test_helper"

module Underwriting
  class SubmitApplicationTest < Test
    cover "Underwriting*"

    def test_application_can_be_submitted
      application_id = SecureRandom.uuid

      assert_events(
        stream(application_id),
        ApplicationSubmitted.new(data: { application_id: application_id, coverage_amount: BigDecimal("1000") })
      ) { submit_application(application_id) }
    end

    def test_application_can_not_be_submitted_twice
      application_id = SecureRandom.uuid
      submit_application(application_id)

      assert_raises(InsuranceApplication::InvalidState) do
        submit_application(application_id)
      end
    end
  end
end
