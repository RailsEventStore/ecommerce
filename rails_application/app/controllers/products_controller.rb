class ProductsController < ApplicationController
  def index
    @products = Products::Product.all
  end

  def show
    @product = Products::Product.find(params[:id])
  end

  def new
    @product_id = SecureRandom.uuid
  end

  def create
    ActiveRecord::Base.transaction do
      create_product(params[:product_id], params[:name])
      if params[:price].present?
        set_product_price(params[:product_id], params[:price])
      end
      if params[:vat_rate].present?
        set_product_vat_rate(params[:product_id], params[:vat_rate])
      end
    rescue ProductCatalog::AlreadyRegistered
      flash[:notice] = "Product was already registered"
      render "new"
    rescue Taxes::Product::VatRateNotApplicable
      flash[:notice] = "Selected VAT rate not applicable"
      render "new"
    else
      redirect_to products_path, notice: "Product was successfully created"
    end
  end

  private

  def create_product(product_id, name)
    command_bus.(create_product_cmd(product_id, name))
  end

  def set_product_price(product_id, price)
    command_bus.(set_product_price_cmd(product_id, price))
  end

  def set_product_vat_rate(product_id, vat_rate_code)
    vat_rate = Taxes::Configuration.available_vat_rates.find{|rate| rate.code == vat_rate_code}
    command_bus.(set_product_vat_rate_cmd(product_id, vat_rate))
  end

  def create_product_cmd(product_id, name)
    ProductCatalog::RegisterProduct.new(product_id: product_id, name: name)
  end

  def set_product_price_cmd(product_id, price)
    Pricing::SetPrice.new(product_id: product_id, price: price)
  end

  def set_product_vat_rate_cmd(product_id, vat_rate)
    Taxes::SetVatRate.new(product_id: product_id, vat_rate: vat_rate)
  end
end
