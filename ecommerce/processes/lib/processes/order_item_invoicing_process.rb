module Processes
  class OrderItemInvoicingProcess
    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def call(event)
      state = build_state(event)
      return unless state.create_invoice_item?

      unit_prices = MoneySplitter.new(state.discounted_amount, Array.new(state.quantity, 1)).call
      unit_prices.tally.each do |unit_price, quantity|
        command_bus.call(Invoicing::AddInvoiceItem.new(
          invoice_id: state.order_id,
          product_id: state.product_id,
          vat_rate: state.vat_rate,
          quantity: quantity,
          unit_price: unit_price
        ))
      end
    end

    private

    attr_reader :event_store, :command_bus

    def build_state(event)
      stream_name = "OrderInvoicingProcess$#{event.data.fetch(:order_id)}$#{event.data.fetch(:product_id)}"
      past = event_store.read.stream(stream_name).to_a
      last_stored = past.size - 1
      event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
      ProcessState.new.tap do |state|
        past.each { |ev| state.call(ev) }
        state.call(event)
      end
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
    end

    class ProcessState
      attr_reader :order_id, :product_id, :quantity, :vat_rate, :discounted_amount

      def call(event)
        @order_id ||= event.data.fetch(:order_id)
        @product_id ||= event.data.fetch(:product_id)
        case event
        when Pricing::PriceItemValueCalculated
          @quantity = event.data.fetch(:quantity)
          @discounted_amount = event.data.fetch(:discounted_amount)
        when Taxes::VatRateDetermined
          @vat_rate = event.data.fetch(:vat_rate).symbolize_keys
        end
      end

      def create_invoice_item?
        [order_id, product_id, quantity, vat_rate, discounted_amount].all?
      end
    end
  end

  class MoneySplitter
    def initialize(amount, weights)
      raise ArgumentError unless weights.instance_of? Array
      raise ArgumentError if weights.empty?
      @amount = amount
      @weights = weights
    end

    def call
      distributed_amounts = []
      total_weight = @weights.sum.to_d
      @weights.each do |weight|
        if total_weight.eql?(0)
          distributed_amounts << 0
          next
        end
        p = weight / total_weight
        distributed_amount = (p * @amount).round(2)
        distributed_amounts << distributed_amount
        total_weight -= weight
        @amount -= distributed_amount
      end
      distributed_amounts
    end
  end
end