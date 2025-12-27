class CouponsController < ApplicationController
  def index
    @coupons = Coupons.coupons_for_store(current_store_id)
  end

  def new
    @coupon_id = SecureRandom.uuid
  end

  def create
    @coupon_id = params[:coupon_id].presence || SecureRandom.uuid
    
    discount = validated_discount(params[:discount])
    return render_invalid_discount unless discount

    ActiveRecord::Base.transaction do
      create_coupon(@coupon_id, discount)
    end
  rescue Pricing::Coupon::AlreadyRegistered
    flash[:notice] = "Coupon is already registered"
    render "new"
  else
    redirect_to coupons_path, notice: "Coupon was successfully created"
  end

  private

  def create_coupon(coupon_id,discount)
    command_bus.(
      Pricing::RegisterCoupon.new(
        coupon_id: coupon_id,
        name: params[:name],
        code: params[:code],
        discount: discount
      )
    )
    command_bus.(
      Stores::RegisterCoupon.new(
        coupon_id: coupon_id,
        store_id: current_store_id
      )
    )
  end

  def validated_discount(raw)
      return nil if raw.blank?

      value = BigDecimal(raw.to_s)
      return nil unless value > 0 && value <= 100

      value
  rescue ArgumentError
      nil
  end

  def render_invalid_discount
    flash.now[:alert] = "Discount must be greater than 0 and less than or equal to 100"
    render "new", status: :unprocessable_entity
  end

end
