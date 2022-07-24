class TimePromotionsController < ApplicationController
  def index
    @time_promotions = TimePromotions::TimePromotion.all
  end

  def new; end

  def create
    id = SecureRandom.uuid

    TimePromotions::TimePromotion.transaction do
      create_time_promotion(id)
      label(id)
      set_discount(id)
      set_range(id)
    end
  rescue ActiveRecord::RecordNotUnique => error
    flash.now[:alert] = error
    render "new"
  else
    redirect_to time_promotions_path, notice: "Time promotion was successfully created"
  end

  private

  def create_time_promotion(id)
    command_bus.(Pricing::CreateTimePromotion.new(time_promotion_id: id))
  end

  def label(id)
    command_bus.(Pricing::LabelTimePromotion.new(time_promotion_id: id, label: params[:label]))
  end

  def set_discount(id)
    command_bus.(Pricing::SetTimePromotionDiscount.new(time_promotion_id: id, discount: params[:discount]))
  end

  def set_range(id)
    command_bus.(
      Pricing::SetTimePromotionRange.new(time_promotion_id: id, start_time: params[:start_time], end_time: params[:end_time])
    )
  end
end
