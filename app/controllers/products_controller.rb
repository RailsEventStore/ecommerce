class ProductsController < ApplicationController
  def index
    @products = ProductCatalog::Product.all
  end

  def new
    @product_uid = SecureRandom.uuid
  end

  def create
    ActiveRecord::Base.transaction do
      product_id = create_product(params[:product_uid], params[:name])
      set_product_price(product_id, params[:price]) if params[:price].present?
    rescue ProductCatalog::Product::AlreadyRegistered
      flash[:notice] = 'Product was already registered.'
      render 'new'
    else
      redirect_to products_path, notice: 'Product was successfully created.'
    end
  end

  private

  def create_product product_uid, name
    command_bus.(create_product_cmd(product_uid, name))
  end

  def set_product_price product_id, price
    command_bus.(set_product_price_cmd(product_id, price))
  end

  def create_product_cmd product_uid, name
    ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: name)
  end

  def set_product_price_cmd product_id, price
    Pricing::SetPrice.new(product_id: product_id, price: price)
  end
end