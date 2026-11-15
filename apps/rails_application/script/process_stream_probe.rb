ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "json"

class ProcessStreamProbe
  SPECS = {
    Processes::ShipmentProcess => {
      prerequisites: {
        Shipping::SubmitShipment => [Fulfillment::OrderRegistered, Shipping::ShippingAddressAddedToShipment],
        Stores::RegisterShipment => [Fulfillment::OrderRegistered, Shipping::ShippingAddressAddedToShipment, Stores::OfferRegistered],
        Shipping::AuthorizeShipment => [Fulfillment::OrderConfirmed, Shipping::ShipmentSubmitted]
      },
      terminal: Shipping::ShipmentAuthorized
    },
    Processes::ReleasePaymentOnOrderExpiration => {
      prerequisites: {
        Payments::ReleasePayment => [Payments::PaymentAuthorized, Pricing::OfferExpired]
      },
      terminal: Payments::PaymentReleased
    }
  }.freeze

  FEEDBACK = {
    Shipping::SubmitShipment => Shipping::ShipmentSubmitted,
    Shipping::AuthorizeShipment => Shipping::ShipmentAuthorized,
    Payments::ReleasePayment => Payments::PaymentReleased
  }.freeze

  ORDER_ID = "00000000-0000-4000-8000-000000000001"
  STORE_ID = "00000000-0000-4000-8000-000000000002"

  def initialize(process_class, feedback, delivery)
    @process_class = process_class
    @feedback = feedback
    @delivery = delivery
    @examples = {}
    @counts = Hash.new(0)
    @traces = 0
    @failing_traces = 0
    @deliveries = 0
  end

  def explore(bound)
    @started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    (0..bound).each do |length|
      @process_class.subscribed_events.repeated_permutation(length) do |trace|
        check(trace)
      end
    end
    {
      process: @process_class.name,
      feedback: @feedback ? "immediate_synthetic" : "withheld",
      delivery: @delivery,
      bound: bound,
      traces: @traces,
      deliveries: @deliveries,
      failing_traces: @failing_traces,
      seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started).round(3),
      violating_traces_by_property: @counts,
      shortest_examples: @examples
    }
  end

  def check(trace)
    @store = Infra::EventStore.in_memory
    @seen = []
    @events = {}
    @commands = []
    @violations = {}
    @inputs = []
    @history = []
    trace.each do |event_class|
      @inputs << event_class.name
      deliver(event_for(event_class))
    rescue RubyEventStore::EventDuplicatedInStream => error
      violation("redelivery_is_noop", error.class.name)
      break
    end
    @traces += 1
    @failing_traces += 1 unless @violations.empty?
    @violations.each do |property, detail|
      @counts[property] += 1
      @examples[property] ||= {
        input: @inputs.dup,
        delivered: @history.dup,
        commands: @commands.dup,
        detail: detail
      }
    end
    @commands
  end

  private

  def spec
    SPECS.fetch(@process_class)
  end

  def event_for(event_class)
    if @delivery == "same_id"
      @events[event_class] ||= new_event(event_class)
    else
      new_event(event_class)
    end
  end

  def new_event(event_class)
    event_class.new(data: {
      order_id: ORDER_ID,
      order_number: "2026/11/15",
      store_id: STORE_ID,
      postal_address: { line_1: "Test address", line_2: "", line_3: "", line_4: "" }
    })
  end

  def deliver(event)
    @deliveries += 1
    @history << event.class.name
    @store.append(event) unless @store.read.event(event.event_id)
    @seen << event.class
    @process_class.new.with(event_store: @store, command_bus: method(:record_command)).call(event)
  end

  def record_command(command)
    violation("prerequisites", command.class.name) unless (spec.fetch(:prerequisites).fetch(command.class) - @seen).empty?
    violation("terminal_quiescence", command.class.name) if @seen.include?(spec.fetch(:terminal))
    violation("at_most_once", command.class.name) if @commands.any? { |previous| previous.fetch(:type) == command.class.name }
    @commands << command_data(command)
    violation("correlation", @commands.last) unless @commands.last.fetch(:order_id) == ORDER_ID
    if command.is_a?(Stores::RegisterShipment) && command.store_id != STORE_ID
      violation("store_correlation", command.store_id)
    end
    deliver(new_event(FEEDBACK.fetch(command.class))) if @feedback && FEEDBACK.key?(command.class)
  end

  def command_data(command)
    if command.is_a?(Stores::RegisterShipment)
      { type: command.class.name, order_id: command.shipment_id, store_id: command.store_id }
    else
      { type: command.class.name, order_id: command.order_id }
    end
  end

  def violation(property, detail)
    @violations[property] ||= detail
  end

  def self.join_controls
    [
      [Processes::ShipmentProcess, [Fulfillment::OrderRegistered, Shipping::ShippingAddressAddedToShipment], Shipping::SubmitShipment],
      [Processes::ReleasePaymentOnOrderExpiration, [Payments::PaymentAuthorized, Pricing::OfferExpired], Payments::ReleasePayment]
    ].map do |process_class, events, command_class|
      {
        process: process_class.name,
        outputs: events.permutation.map { |trace| new(process_class, false, "fresh_id").check(trace) }
      }.tap do |control|
        unless control.fetch(:outputs).all? { |output| output == [{ type: command_class.name, order_id: ORDER_ID }] }
          raise "Join commands differ from contract: #{control}"
        end
      end
    end
  end

  def self.synchronous_controls
    [
      [Processes::ShipmentProcess,
       [Fulfillment::OrderRegistered, Shipping::ShippingAddressAddedToShipment, Fulfillment::OrderConfirmed,
        Fulfillment::OrderRegistered, Shipping::ShippingAddressAddedToShipment, Stores::OfferRegistered],
       [Shipping::SubmitShipment, Shipping::AuthorizeShipment]],
      [Processes::ReleasePaymentOnOrderExpiration,
       [Payments::PaymentAuthorized, Pricing::OfferExpired, Pricing::OfferExpired,
        Fulfillment::OrderRegistered, Fulfillment::OrderConfirmed],
       [Payments::ReleasePayment]]
    ].map do |process_class, events, commands|
      {
        process: process_class.name,
        commands: new(process_class, true, "fresh_id").check(events)
      }.tap do |control|
        unless control.fetch(:commands) == commands.map { |command| { type: command.name, order_id: ORDER_ID } }
          raise "Synchronous commands differ from contract: #{control}"
        end
      end
    end
  end

  def self.run
    {
      ruby: RUBY_DESCRIPTION,
      join_controls: join_controls,
      synchronous_controls: synchronous_controls,
      results: SPECS.keys.product([false, true], ["fresh_id", "same_id"]).map do |process_class, feedback, delivery|
        new(process_class, feedback, delivery).explore(Integer(ENV.fetch("BOUND", "4")))
      end
    }.tap do |report|
      puts(JSON.pretty_generate(report))
      exit(1) if ENV["STRICT"] == "1" && report.fetch(:results).any? { |result| result.fetch(:failing_traces).positive? }
    end
  end
end

ProcessStreamProbe.run if $PROGRAM_NAME == __FILE__
