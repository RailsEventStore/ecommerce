class CouponsController < ApplicationController
  def index
    @coupons = Coupons.coupons_for_store(current_store_id)
  end

  def new
    @coupon_id = SecureRandom.uuid
  end

  def create
    coupon_id = params[:coupon_id]

    ActiveRecord::Base.transaction do
      create_coupon(coupon_id)
    end
  rescue Pricing::Coupon::AlreadyRegistered
    flash[:notice] = "Coupon is already registered"
    render "new"
  else
    redirect_to coupons_path, notice: "Coupon was successfully created"
  end

  private

  def create_coupon(coupon_id)
    command_bus.(
      Pricing::RegisterCoupon.new(
        coupon_id: coupon_id,
        name: params[:name],
        code: params[:code],
        discount: params[:discount]
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
