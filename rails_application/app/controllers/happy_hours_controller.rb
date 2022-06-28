class HappyHoursController < ApplicationController
  def index
    @happy_hours = HappyHours::HappyHour.all
  end

  def new
    @happy_hour_id = SecureRandom.uuid
    @products = Products::Product.all
  end

  def create
    create_happy_hour(
      **params.permit(
        :happy_hour_id, :name, :code, :discount, :start_hour, :end_hour, product_ids: []
      )
    )
  rescue Pricing::HappyHour::AlreadyCreated
    flash[:alert] = "Happy hour is already created"
    @happy_hour_id = SecureRandom.uuid
    @products = Products::Product.all
    render "new"
  else
    redirect_to happy_hours_path, notice: "Happy hour was successfully created"
  end

  private

  def create_happy_hour(**kwargs)
    command_bus.(create_happy_hour_cmd(**kwargs))
  end

  def create_happy_hour_cmd(**kwargs)
    Pricing::CreateHappyHour.new(**kwargs.symbolize_keys)
  end

  def product_names_for(happy_hour)
    Products::Product.where(id: happy_hour.product_ids).pluck(:name).join(", ")
  end
  helper_method :product_names_for
end
