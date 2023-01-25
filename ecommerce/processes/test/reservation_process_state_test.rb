require_relative "test_helper"

module Processes
  class ReservationProcessStateTest < Test
    cover "Processes::ReservationProcess::State*"

    def test_complete_state_is_set
      state = ReservationProcess::ProcessState.new
      state.call(order_confirmed)
      assert_equal :complete, state.state
    end

    def test_abandoned_state_is_set
      state = ReservationProcess::ProcessState.new
      state.call(order_cancelled)
      assert_equal :abandoned, state.state
    end
  end
end