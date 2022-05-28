class HappyHoursController < ApplicationController
  def index
    @happy_hours = HappyHours::HappyHour.all
  end

  def new
    @happy_hour_id = SecureRandom.uuid
  end

  def create
    create_happy_hour(params.slice(:name, :code, :discount, :start_hour, :end_hour, :product_ids))
  rescue Pricing::HappyHour::AlreadyCreated
    flash[:notice] = "Happy hour is already created"
    render "new"
  else
    redirect_to happy_hours_path, notice: "Happy hour was successfully created"
  end

  private

  def create_happy_hour(**kwargs)
    command_bus.(create_happy_hour_cmd(kwargs))
  end

  def create_happy_hour_cmd(**kwargs)
    Pricing::CreateHappyHour.new(kwargs)
  end
end
