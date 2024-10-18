class AvailableVatRatesController < ApplicationController
  class AvailableVatRateForm
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_reader :code, :rate

    def initialize(params)
      @code = params[:code]
      @rate = params[:rate]
    end

    validates :code, presence: true
    validates :rate, presence: true, numericality: { greater_than: 0 }
  end

  def new
  end

  def create
    available_vat_rate_id = SecureRandom.uuid
    available_vat_rate_form = AvailableVatRateForm.new(available_vat_rate_params)

    unless available_vat_rate_form.valid?
      return render "new", locals: { errors: available_vat_rate_form.errors }, status: :unprocessable_entity
    end

    add_available_vat_rate(available_vat_rate_form.code, available_vat_rate_form.rate, available_vat_rate_id)
  rescue Taxes::VatRateAlreadyExists
    flash.now[:alert] = "VAT rate already exists"
    render "new", status: :unprocessable_entity
  else
    redirect_to available_vat_rates_path, notice: "VAT rate was successfully created"
  end

  def index
    @available_vat_rates = VatRates::AvailableVatRate.all
  end

  def destroy
    remove_available_vat_rate(params[:vat_rate_code])
    redirect_to available_vat_rates_path, notice: "VAT rate was successfully removed"
  rescue Taxes::VatRateNotExists
    redirect_to available_vat_rates_path, alert: "VAT rate does not exist"
  end

  private

  def add_available_vat_rate(code, rate, available_vat_rate_id)
    command_bus.(add_available_vat_rate_cmd(code, rate, available_vat_rate_id))
  end

  def add_available_vat_rate_cmd(code, rate, available_vat_rate_id)
    Taxes::AddAvailableVatRate.new(
      available_vat_rate_id: available_vat_rate_id,
      vat_rate: Infra::Types::VatRate.new(code: code, rate: rate)
    )
  end

  def remove_available_vat_rate(vat_rate_code)
    command_bus.(remove_available_vat_rate_cmd(vat_rate_code))
  end

  def remove_available_vat_rate_cmd(vat_rate_code)
    Taxes::RemoveAvailableVatRate.new(vat_rate_code: vat_rate_code)
  end

  def available_vat_rate_params
    params.permit(:code, :rate)
  end
end
