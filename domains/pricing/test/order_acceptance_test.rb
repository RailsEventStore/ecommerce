require_relative "test_helper"

module Pricing
  class OrderAcceptanceTest < Test
    cover "Pricing::OrderAcceptance*"
    cover "Pricing::OnRequestOrderAcceptance*"
    cover "Pricing::OnRejectEmptyOrderAcceptance*"

    def test_requests_acceptance_without_accepting_the_offer
      assert_no_events("Pricing::Offer$#{order_id}") do
        assert_events(
          "Pricing::OrderAcceptance$#{order_id}",
          OrderAcceptanceRequested.new(data: { order_id: order_id })
        ) { request_acceptance }
      end
    end

    def test_acceptance_can_be_requested_again
      request_acceptance

      assert_events(
        "Pricing::OrderAcceptance$#{order_id}",
        OrderAcceptanceRequested.new(data: { order_id: order_id })
      ) { request_acceptance }
    end

    def test_records_why_acceptance_was_rejected_without_rejecting_an_accepted_offer
      request_acceptance

      assert_no_events("Pricing::Offer$#{order_id}") do
        assert_events(
          "Pricing::OrderAcceptance$#{order_id}",
          EmptyOrderAcceptanceRejected.new(data: { order_id: order_id })
        ) { run_command(RejectEmptyOrderAcceptance.new(order_id)) }
      end

      assert_events(
        "Pricing::OrderAcceptance$#{order_id}",
        OrderAcceptanceRequested.new(data: { order_id: order_id })
      ) { request_acceptance }
    end

    private

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def request_acceptance
      run_command(RequestOrderAcceptance.new(order_id))
    end
  end
end
