module Taxes
  class SetVatRateHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Product, cmd.product_id) do |product|
        product.set_vat_rate(cmd.vat_rate)
      end
    end
  end
end