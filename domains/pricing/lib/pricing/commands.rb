module Pricing
  class DraftOffer
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id
    alias aggregate_id order_id

    def initialize(order_id)
      @order_id = order_id
      valid = UUID.match?(@order_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class AddPriceItem
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :product_id, :price
    alias aggregate_id order_id

    def initialize(order_id, product_id, price)
      @order_id = order_id
      @product_id = product_id
      @price = BigDecimal(price)
      valid = UUID.match?(@order_id) && UUID.match?(@product_id) && @price >= 0
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RemovePriceItem
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :product_id
    alias aggregate_id order_id

    def initialize(order_id, product_id)
      @order_id = order_id
      @product_id = product_id
      valid = UUID.match?(@order_id) && UUID.match?(@product_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class SetPrice
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :product_id, :price

    def initialize(product_id, price)
      @product_id = product_id
      @price = BigDecimal(price)
      valid = UUID.match?(@product_id) && @price >= 0
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class SetFuturePrice
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :product_id, :price, :valid_since

    def initialize(product_id, price, valid_since)
      @product_id = product_id
      @price = BigDecimal(price)
      @valid_since = valid_since
      valid = UUID.match?(@product_id) && @price >= 0 && @valid_since.is_a?(Time)
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class SetPercentageDiscount
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :amount
    alias aggregate_id order_id

    def initialize(order_id, amount)
      @order_id = order_id
      @amount = BigDecimal(amount)
      valid = UUID.match?(@order_id) && @amount > 0 && @amount <= 100
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RemovePercentageDiscount
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id
    alias aggregate_id order_id

    def initialize(order_id)
      @order_id = order_id
      valid = UUID.match?(@order_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class SetTimePromotionDiscount
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :amount
    alias aggregate_id order_id

    def initialize(order_id, amount)
      @order_id = order_id
      @amount = BigDecimal(amount)
      valid = UUID.match?(@order_id) && @amount > 0 && @amount <= 100
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RemoveTimePromotionDiscount
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id
    alias aggregate_id order_id

    def initialize(order_id)
      @order_id = order_id
      valid = UUID.match?(@order_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RegisterCoupon
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :coupon_id, :name, :code, :discount
    alias aggregate_id coupon_id

    def initialize(coupon_id, name, code, discount)
      @coupon_id = coupon_id
      @name = name
      @code = code
      @discount = BigDecimal(discount)
      valid = UUID.match?(@coupon_id) && @name.is_a?(String) && @code.is_a?(String) && @discount > 0 && @discount <= 100
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class CreateTimePromotion
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    UNDEFINED = Object.new
    attr_reader :time_promotion_id, :discount, :start_time, :end_time, :label

    def initialize(time_promotion_id = UNDEFINED, discount, start_time, end_time, label)
      id_omitted = time_promotion_id.equal?(UNDEFINED)
      @time_promotion_id = time_promotion_id unless id_omitted
      @discount = BigDecimal(discount)
      @start_time = start_time
      @end_time = end_time
      @label = label
      valid = (id_omitted || UUID.match?(@time_promotion_id)) && @discount > 0 && @discount <= 100 && @start_time.is_a?(Time) && @end_time.is_a?(Time) && @label.is_a?(String)
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class ChangePercentageDiscount
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :amount
    alias aggregate_id order_id

    def initialize(order_id, amount)
      @order_id = order_id
      @amount = BigDecimal(amount)
      valid = UUID.match?(@order_id) && @amount > 0 && @amount <= 100
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class MakeProductFreeForOrder
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :product_id
    alias aggregate_id order_id

    def initialize(order_id, product_id)
      @order_id = order_id
      @product_id = product_id
      valid = UUID.match?(@order_id) && UUID.match?(@product_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RemoveFreeProductFromOrder
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :product_id
    alias aggregate_id order_id

    def initialize(order_id, product_id)
      @order_id = order_id
      @product_id = product_id
      valid = UUID.match?(@order_id) && UUID.match?(@product_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class UseCoupon
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :coupon_id, :discount
    alias aggregate_id order_id

    def initialize(order_id, coupon_id, discount)
      @order_id = order_id
      @coupon_id = coupon_id
      @discount = BigDecimal(discount)
      valid = UUID.match?(@order_id) && UUID.match?(@coupon_id) && @discount > 0 && @discount <= 100
    rescue StandardError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class AcceptOffer
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id
    alias aggregate_id order_id

    def initialize(order_id)
      @order_id = order_id
      valid = UUID.match?(@order_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RejectOffer
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id, :reason, :unavailable_product_ids
    alias aggregate_id order_id

    def initialize(order_id, reason, unavailable_product_ids = nil)
      @order_id = order_id
      @reason = reason
      @unavailable_product_ids = unavailable_product_ids
      valid = UUID.match?(@order_id) && @reason.is_a?(String) && valid_product_ids?
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end

    private

    def valid_product_ids?
      @unavailable_product_ids.nil? || (@unavailable_product_ids.is_a?(Array) && @unavailable_product_ids.all? { |id| UUID.match?(id) })
    end
  end

  class ExpireOffer
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :order_id
    alias aggregate_id order_id

    def initialize(order_id)
      @order_id = order_id
      valid = UUID.match?(@order_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
