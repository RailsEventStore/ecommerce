class CouponsController < ApplicationController
  def index
    @coupons = Coupons::Coupon.all
  end

  def new
    @coupon_id = SecureRandom.uuid
  end

  def create
    create_coupon(params[:coupon_id], params[:name], params[:code], params[:discount])
  rescue Pricing::Coupon::AlreadyRegistered
    flash[:notice] = "Coupon is already registered"
    render "new"
  else
    redirect_to coupons_path, notice: "Coupon was successfully created"
  end

  private

  def create_coupon(coupon_id, name, code, discount)
    command_bus.(create_coupon_cmd(coupon_id, name, code, discount))
  end

  def create_coupon_cmd(coupon_id, name, code, discount)
    Pricing::RegisterCoupon.new(coupon_id: coupon_id, name: name, code: code, discount: discount)
  end

end
