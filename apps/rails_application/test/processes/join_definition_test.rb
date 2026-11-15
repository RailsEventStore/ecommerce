require "test_helper"

module Processes
  class JoinDefinitionTest < ProcessTest
    cover "Processes::JoinDefinition*"

    def test_mixed_join_requires_both_sides_of_each_alternative
      assert_equal([], definition.decide(evolve(order_placed)))
      assert_equal([], definition.decide(evolve(payment_authorized)))
      assert_equal([:release_payment], definition.decide(evolve(order_placed, payment_authorized)))
      assert_equal([:release_payment], definition.decide(evolve(order_expired, payment_authorized)))
      assert_equal([], definition.decide(evolve(order_placed, order_expired)))
      assert_equal([], definition.decide(evolve(order_placed, payment_authorized, order_confirmed)))
    end

    def test_releasing_payment_removes_authorization_and_completion_is_opt_in
      assert_equal([], definition.decide(evolve(order_expired, payment_authorized, payment_released)))
      assert_equal([:release_payment], definition.decide(evolve(order_expired, payment_authorized, payment_released, payment_authorized)))
      assert_nil(evolve(payment_released).outcome)
      assert_equal(:Completed, definition.evolve(JoinDefinition::State.new, payment_released, true).outcome)
    end

    def test_terminal_outcomes_absorb_later_events
      [
        [payment_released, :Completed],
        [JoinDefinition::TimedOut.new(data: { order_id: order_id }), :TimedOut],
        [JoinDefinition::Killed.new(data: { order_id: order_id }), :Killed]
      ].each do |event, outcome|
        assert_equal(outcome, definition.evolve(JoinDefinition::State.new, event, true).outcome)
        assert_equal([], definition.decide(definition.evolve(JoinDefinition::State.new, event, true)))
        assert_equal(outcome, definition.evolve(definition.evolve(JoinDefinition::State.new, event, true), payment_authorized, true).outcome)
        assert_equal([], definition.decide(definition.evolve(evolve(order_expired, payment_authorized), event, true)))
      end
    end

    def test_nonterminal_bounded_state_preserves_event_payload
      assert_nil(definition.evolve(JoinDefinition::State.new, order_placed, true).outcome)
      assert_equal(order_placed.data, evolve(order_placed).events.fetch(Fulfillment::OrderRegistered).data)
    end

    def test_first_enabled_rule_wins
      assert_equal(
        [:first],
        JoinDefinition.new(
          [
            JoinDefinition::Rule.new(JoinDefinition.event(Payments::PaymentAuthorized), :first, JoinDefinition::Pattern.new([])),
            JoinDefinition::Rule.new(JoinDefinition.event(Payments::PaymentAuthorized), :second, JoinDefinition::Pattern.new([]))
          ],
          {},
          JoinDefinition.event(Payments::PaymentReleased)
        ).decide(evolve(payment_authorized))
      )
    end

    def test_specification_describes_join_blocker_and_completion
      assert_equal(
        "Given (Fulfillment::OrderRegistered & Payments::PaymentAuthorized | Pricing::OfferExpired & Payments::PaymentAuthorized); unless (Fulfillment::OrderConfirmed); when an event arrives; then release_payment\nCompleted on (Payments::PaymentReleased)\nTimedOut on Processes::JoinDefinition::TimedOut\nKilled on Processes::JoinDefinition::Killed",
        definition.specification
      )
    end

    private

    def definition
      JoinDefinition.new(
        [JoinDefinition::Rule.new(
          (JoinDefinition.event(Fulfillment::OrderRegistered) | JoinDefinition.event(Pricing::OfferExpired)) & JoinDefinition.event(Payments::PaymentAuthorized),
          :release_payment,
          JoinDefinition.event(Fulfillment::OrderConfirmed)
        )],
        { Payments::PaymentReleased => Payments::PaymentAuthorized },
        JoinDefinition.event(Payments::PaymentReleased)
      )
    end

    def evolve(*events)
      events.reduce(JoinDefinition::State.new) { |state, event| definition.evolve(state, event) }
    end
  end
end
