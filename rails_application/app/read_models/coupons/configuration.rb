module Coupons
  class Coupon < ApplicationRecord
    self.table_name = "coupons"
  end

  private_constant :Coupon

  def self.coupons_for_store(store_id)
    Coupon.where(store_id: store_id)
  end

  def self.find_by_code_for_store(code, store_id)
    Coupon.find_by!("lower(code) = ? AND store_id = ?", code.downcase, store_id)
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(RegisterCoupon.new, to: [Pricing::CouponRegistered])
      event_store.subscribe(AssignStoreToCoupon.new, to: [Stores::CouponRegistered])
    end
  end
end
