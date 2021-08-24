class ProductsController < ApplicationController
  def index
    @products = Products::Product.all
  end

  def new
    @product_id = SecureRandom.uuid
  end

  def create
    ActiveRecord::Base.transaction do
      create_product(params[:product_id], params[:name])
      set_product_price(params[:product_id], params[:price]) if params[:price].present?
    rescue ProductCatalog::Product::AlreadyRegistered
      flash[:notice] = 'Product was already registered.'
      render 'new'
    else
      redirect_to products_path, notice: 'Product was successfully created.'
    end
  end

  private

  def create_product(product_id, name)
    command_bus.(create_product_cmd(product_id, name))
  end

  def set_product_price(product_id, price)
    command_bus.(set_product_price_cmd(product_id, price))
  end

  def create_product_cmd(product_id, name)
    ProductCatalog::RegisterProduct.new(product_id: product_id, name: name)
  end

  def set_product_price_cmd(product_id, price)
    Pricing::SetPrice.new(product_id: product_id, price: price)
  end
end