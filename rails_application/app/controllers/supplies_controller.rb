class SuppliesController < ApplicationController
  def new
    @product_id = params[:product_id]
  end

  def create
    supply(params[:product_id], params[:quantity])
    redirect_to products_path, notice: "Stock level changed"
  end

  private

  def supply(product_id, quantity)
    command_bus.(
      Inventory::Supply.new(product_id: product_id, quantity: quantity)
    )
  end
end
