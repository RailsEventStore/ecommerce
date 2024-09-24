class SuppliesController < ApplicationController
  def new
    @product_id = params[:product_id]
  end

  def create
    Inventory::ProductService.new.supply(params[:product_id], params[:quantity].to_i)
    redirect_to products_path, notice: "Stock level changed"
  end
end
