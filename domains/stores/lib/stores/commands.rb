module Stores
  class RegisterStore
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id

    def initialize(store_id)
      @store_id = store_id
      valid = UUID.match?(@store_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class NameStore
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :name

    def initialize(store_id, name)
      @store_id = store_id
      @name = name
      valid = UUID.match?(@store_id) && @name.is_a?(StoreName)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterProduct
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :product_id

    def initialize(store_id, product_id)
      @store_id = store_id
      @product_id = product_id
      valid = UUID.match?(@store_id) && UUID.match?(@product_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterCustomer
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :customer_id

    def initialize(store_id, customer_id)
      @store_id = store_id
      @customer_id = customer_id
      valid = UUID.match?(@store_id) && UUID.match?(@customer_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterOffer
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :order_id

    def initialize(store_id, order_id)
      @store_id = store_id
      @order_id = order_id
      valid = UUID.match?(@store_id) && UUID.match?(@order_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterTimePromotion
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :time_promotion_id

    def initialize(store_id, time_promotion_id)
      @store_id = store_id
      @time_promotion_id = time_promotion_id
      valid = UUID.match?(@store_id) && UUID.match?(@time_promotion_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterCoupon
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :coupon_id

    def initialize(store_id, coupon_id)
      @store_id = store_id
      @coupon_id = coupon_id
      valid = UUID.match?(@store_id) && UUID.match?(@coupon_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterInvoice
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :invoice_id

    def initialize(store_id, invoice_id)
      @store_id = store_id
      @invoice_id = invoice_id
      valid = UUID.match?(@store_id) && UUID.match?(@invoice_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterShipment
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :shipment_id

    def initialize(store_id, shipment_id)
      @store_id = store_id
      @shipment_id = shipment_id
      valid = UUID.match?(@store_id) && UUID.match?(@shipment_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterVatRate
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :store_id, :vat_rate_id

    def initialize(store_id, vat_rate_id)
      @store_id = store_id
      @vat_rate_id = vat_rate_id
      valid = UUID.match?(@store_id) && UUID.match?(@vat_rate_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
