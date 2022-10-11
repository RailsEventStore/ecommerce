require "infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/events"
require_relative "product_catalog/registration"
require_relative "product_catalog/naming"

module ProductCatalog

  class Configuration
    def call(cqrs)
      cqrs.register_command(RegisterProduct, Registration.new(cqrs))
      cqrs.register_command(NameProduct, Naming.new(cqrs))
    end
  end
end
