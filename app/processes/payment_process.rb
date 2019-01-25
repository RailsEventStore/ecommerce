class PaymentProcess
  def initialize(store: Rails.configuration.event_store,
                 bus: Rails.configuration.command_bus)
    @store = store
    @bus = bus
  end

  def call(event)
    state = build_state(event)
    if state.release?
      bus.call(Payments::ReleasePayment.new(
        order_id: state.order_id,
        transaction_id: state.transaction_id))
    end
  end

  private
  attr_reader :store, :bus

  def build_state(event)
    stream_name = "PaymentProcess$#{event.data.fetch(:order_id)}"
    past = store.read.stream(stream_name).to_a
    last_stored = past.size - 1
    store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
    ProcessState.new.tap do |state|
      past.each{|ev| state.call(ev)}
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
    attr_reader :transaction_id, :order_id

    def call(event)
      case event
      when Payments::PaymentAuthorized
        @payment = :authorized
        @transaction_id = event.data.fetch(:transaction_id)
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
