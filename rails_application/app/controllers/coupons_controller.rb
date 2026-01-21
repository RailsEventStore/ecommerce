class CouponsController < ApplicationController
  def index
    @coupons = Coupons.coupons_for_store(current_store_id)
  end

  def new
    @coupon_id = SecureRandom.uuid
  end

  def create
    @coupon_id = params[:coupon_id].presence || SecureRandom.uuid

    discount = Pricing::CouponDiscount.parse(params[:discount])

    ActiveRecord::Base.transaction do
      create_coupon(@coupon_id, discount)
    end
  rescue Pricing::CouponDiscount::UnacceptableRange, Pricing::CouponDiscount::Unparseable
    flash.now[:alert] = "Discount must be greater than 0 and less than or equal to 100"
    render "new", status: :unprocessable_entity
  rescue Pricing::Coupon::AlreadyRegistered
    flash.now[:alert] = "Coupon is already registered"
    render "new", status: :unprocessable_entity
  rescue Infra::Command::Invalid
    flash.now[:alert] = "Invalid coupon data"
    render "new", status: :unprocessable_entity
  else
    redirect_to coupons_path, notice: "Coupon was successfully created"
  end

  private

  def create_coupon(coupon_id, discount)
    command_bus.(
      Pricing::RegisterCoupon.new(
        coupon_id: coupon_id,
        name: params[:name],
        code: params[:code],
        discount: discount.to_d
      )
    )
    command_bus.(
      Stores::RegisterCoupon.new(
        coupon_id: coupon_id,
        store_id: current_store_id
      )
    )
  end
end