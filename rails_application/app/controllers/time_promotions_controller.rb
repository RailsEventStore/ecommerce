class TimePromotionsController < ApplicationController
  def index
    @time_promotions = TimePromotion.all
  end

  def new; end

  def create
    TimePromotion.create!(
      start_time: Time.parse(params[:start_time]),
      end_time: Time.parse(params[:end_time]),
      label: params[:label],
      discount: params[:discount]
    )
    redirect_to time_promotions_path, notice: "Time promotion was successfully created"
  end
end
