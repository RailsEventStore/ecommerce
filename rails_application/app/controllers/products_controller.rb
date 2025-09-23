class ProductsController < ApplicationController
  class ProductForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    attribute :name, :string
    attribute :price, :decimal
    attribute :vat_rate_code, :string
    attribute :product_id, :string

    validates :name, presence: true
    validates :price, presence: true, numericality: { greater_than: 0 }
    validates :vat_rate_code, presence: true
    validates :product_id, presence: true
  end

  def index
    @products = Products::Product.where(archived: false)
  end

  def show
    @product = Products::Product.find(params[:id])
  end

  def new
    @product_id = SecureRandom.uuid
  end

  def edit
    @product = Products::Product.find(params[:id])
  end

  def create
    product_form = ProductForm.new(**product_params)

    unless product_form.valid?
      return render "new", locals: { errors: product_form.errors }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      create_product(product_form.product_id, product_form.name)
      if product_form.price.present?
        set_product_price(product_form.product_id, product_form.price)
      end
      if product_form.vat_rate_code.present?
        set_product_vat_rate(product_form.product_id, product_form.vat_rate_code)
      end
    end

    redirect_to products_path, notice: "Product was successfully created"
  rescue ProductCatalog::AlreadyRegistered
    flash[:notice] = "Product was already registered"
    render "new"
  rescue Taxes::VatRateNotApplicable
    flash[:notice] = "Selected VAT rate is not applicable"
    render "new"
  end

  def update
    if params[:name].present?
      set_product_name(params[:product_id], params[:name])
    end
    if params[:price].present?
      set_product_price(params[:product_id], params[:price])
    end
    if params[:future_prices].present?
      params[:future_prices].each do |future_price|
        set_future_product_price(
          params[:product_id],
          future_price["price"],
          Time.zone.parse(future_price["start_time"]).utc
        )
      end
    end
    redirect_to products_path, notice: "Product was successfully updated"
  end

  def archive
    command_bus.(ProductCatalog::ArchiveProduct.new(product_id: params[:id]))
    redirect_to products_path, notice: "Product was archived"
  end

  private

  def create_product(product_id, name)
    command_bus.(create_product_cmd(product_id))
    command_bus.(name_product_cmd(product_id, name))
  end

  def set_product_price(product_id, price)
    command_bus.(set_product_price_cmd(product_id, price))
  end

  def set_future_product_price(product_id, price, valid_since)
    command_bus.(set_product_future_price_cmd(product_id, price, valid_since))
  end

  def set_product_vat_rate(product_id, vat_rate_code)
    command_bus.(set_product_vat_rate_cmd(product_id, vat_rate_code))
  end

  def set_product_name(product_id, name)
    command_bus.(name_product_cmd(product_id, name))
  end

  def create_product_cmd(product_id)
    ProductCatalog::RegisterProduct.new(product_id: product_id)
  end

  def name_product_cmd(product_id, name)
    ProductCatalog::NameProduct.new(product_id: product_id, name: name)
  end

  def set_product_price_cmd(product_id, price)
    Pricing::SetPrice.new(product_id: product_id, price: price)
  end

  def set_product_vat_rate_cmd(product_id, vat_rate_code)
    Taxes::SetVatRate.new(product_id: product_id, vat_rate_code: vat_rate_code)
  end

  def set_product_future_price_cmd(product_id, price, valid_since)
    Pricing::SetFuturePrice.new(
      product_id: product_id,
      price: price,
      valid_since: valid_since
    )
  end

  def product_params
    params.permit(:name, :price, :vat_rate_code, :product_id).to_h.symbolize_keys.slice(:price, :vat_rate_code, :name, :product_id)
  end
end
