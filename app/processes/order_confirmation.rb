class OrderConfirmation
  def initialize(store: Rails.configuration.event_store,
                 bus: Rails.configuration.command_bus)
    @store = store
    @bus = bus
  end

  def call(event)
    state = build_state(event)
    if state.confirm_order?
      bus.call(Ordering::MarkOrderAsPaid.new(order_id: state.order_id))
    end
  end

  private
  attr_reader :store, :bus

  def build_state(event)
    stream_name = "OrderConfirmation$#{event.data.fetch(:order_id)}"
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
      @order_id = nil
      @payment  = nil
    end
    attr_reader :order_id

    def call(event)
      case event
      when Payments::PaymentAuthorized
        @payment = :authorized
        @order_id = event.data.fetch(:order_id)
      when Payments::PaymentCaptured
        @payment = :captured
      end
    end

    def confirm_order?
      @payment == :captured
    end
  end
end