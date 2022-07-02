class HappyHoursController < ApplicationController
  def index
    @happy_hours = HappyHours::HappyHour.all
  end

  def new; end

  def create
    create_happy_hour(
      **params.permit(
        :name, :code, :discount, :start_hour, :end_hour
      )
    )
  rescue Pricing::HappyHour::AlreadyCreated
    flash[:alert] = "Happy hour with generated id is already created (not useful to the user)"
    render "new"
  rescue Pricing::OverlappingHappyHours => e
    flash[:alert] = e.message
    render "new"
  else
    redirect_to happy_hours_path, notice: "Happy hour was successfully created"
  end

  private

  def create_happy_hour(**kwargs)
    command_bus.(create_happy_hour_cmd(**kwargs))
  end

  def create_happy_hour_cmd(**kwargs)
    Pricing::CreateHappyHour.new(details: kwargs.symbolize_keys)
  end
end
