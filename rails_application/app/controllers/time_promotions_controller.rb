class TimePromotionsController < ApplicationController
  def index
    @time_promotions = TimePromotions.time_promotions_for_store(current_store_id)
  end

  def new; end

  def create
    id = SecureRandom.uuid

    ActiveRecord::Base.transaction do
      create_time_promotion(id)
    end
  rescue ActiveRecord::RecordNotUnique => error
    flash.now[:alert] = error
    render "new"
  else
    respond_to do |format|
      format.html { redirect_to time_promotions_path, notice: "Time promotion was successfully created" }
      format.turbo_stream { head :ok }
    end
  end

  private

  def create_time_promotion(id)
    command_bus.(
      Pricing::CreateTimePromotion.new(
        time_promotion_id: id,
        discount: params[:discount],
        start_time: Time.zone.parse(params[:start_time]),
        end_time: Time.zone.parse(params[:end_time]),
        label: params[:label]
      )
    )
    command_bus.(
      Stores::RegisterTimePromotion.new(
        time_promotion_id: id,
        store_id: current_store_id
      )
    )
  end
end
