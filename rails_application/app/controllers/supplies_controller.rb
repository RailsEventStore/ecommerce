class SuppliesController < ApplicationController
  class SupplyForm
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_reader :product_id, :quantity

    def initialize(params)
      @product_id = params[:product_id]
      @quantity = params[:quantity]
    end

    validates :product_id, presence: true
    validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0, allow_blank: true, only_numeric: true }
  end

  def new
    @product_id = params[:product_id]
  end

  def create
    supply_form = SupplyForm.new(supply_params)

    unless supply_form.valid?
      return render "new", locals: { errors: supply_form.errors }, status: :unprocessable_entity
    end

    supply(supply_form.product_id, supply_form.quantity.to_i)
    redirect_to products_path, notice: "Stock level changed"
  end

  private

  def supply(product_id, quantity)
    command_bus.(
      Inventory::Supply.new(product_id: product_id, quantity: quantity)
    )
  end

  def supply_params
    params.permit(:product_id, :quantity)
  end
end
