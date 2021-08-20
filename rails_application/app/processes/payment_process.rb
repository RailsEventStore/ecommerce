class PaymentProcess
  def initialize(store: Rails.configuration.event_store,
                 bus: Rails.configuration.command_bus)
    @store = store
    @bus = bus
  end

  def call(event)
    state = build_state(event)
    release_payment(state) if state.release?
  end

  private

  def release_payment(state)
    bus.call(Payments::ReleasePayment.new(order_id: state.order_id))
  end

  attr_reader :store, :bus

  def build_state(event)
    stream_name = "PaymentProcess$#{event.data.fetch(:order_id)}"
    past_events = store.read.stream(stream_name).to_a
    last_stored = past_events.size - 1
    store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
    ProcessState.new.tap do |state|
      past_events.each{|ev| state.call(ev)}
      state.call(event)
    end
  rescue RubyEventStore::WrongExpectedEventVersion
    retry
  end

  class ProcessState
    def initialize
      @order = :draft
      @payment = :none
    end
    attr_reader :order_id

    def call(event)
      case event
      when Payments::PaymentAuthorized
        @payment = :authorized
      when Payments::PaymentReleased
        @payment = :released
      when Ordering::OrderSubmitted
        @order = :submitted
        @order_id = event.data.fetch(:order_id)
      when Ordering::OrderExpired
        @order = :expired
      when Ordering::OrderPaid
        @order = :paid
      end
    end

    def release?
      @payment == :authorized && @order == :expired
    end
  end
end
