require "infra"
require_relative "stores/store_name"
require_relative "stores/commands"
require_relative "stores/events"
require_relative "stores/registration"
require_relative "stores/naming"
require_relative "stores/product_registration"
require_relative "stores/customer_registration"
require_relative "stores/offer_registration"
require_relative "stores/time_promotion_registration"
require_relative "stores/coupon_registration"
require_relative "stores/invoice_registration"

module Stores

  class Configuration
    def call(event_store, command_bus)
      command_bus.register(RegisterStore, Registration.new(event_store))
      command_bus.register(NameStore, Naming.new(event_store))
      command_bus.register(RegisterProduct, ProductRegistration.new(event_store))
      command_bus.register(RegisterCustomer, CustomerRegistration.new(event_store))
      command_bus.register(RegisterOffer, OfferRegistration.new(event_store))
      command_bus.register(RegisterTimePromotion, TimePromotionRegistration.new(event_store))
      command_bus.register(RegisterCoupon, CouponRegistration.new(event_store))
      command_bus.register(RegisterInvoice, InvoiceRegistration.new(event_store))
    end
  end
end
