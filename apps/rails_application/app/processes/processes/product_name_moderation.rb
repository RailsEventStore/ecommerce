module Processes
  class ProductNameModeration

    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      case event
      when ProductCatalog::ProductNameChangeRequested
        command_bus.call(
          ProductCatalog::ModerateProductName.new(
            event.data.fetch(:product_id),
            event.data.fetch(:name)
          )
        )
      when ProductCatalog::ProductNameApproved
        command_bus.call(
          ProductCatalog::NameProduct.new(
            event.data.fetch(:product_id),
            event.data.fetch(:name)
          )
        )
      end
    end

    private
    attr_reader :command_bus
  end
end
