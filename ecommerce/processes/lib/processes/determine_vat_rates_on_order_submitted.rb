module Processes
  class DetermineVatRatesOnOrderSubmitted
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call(event)
      order_id = event.data.fetch(:order_id)
      event.data.fetch(:order_lines).each do |product_id, quantity|
        command = Taxes::DetermineVatRate.new(order_id: order_id, product_id: product_id)
        cqrs.run(command)
      end
    end

    private

    attr_reader :cqrs
  end
end