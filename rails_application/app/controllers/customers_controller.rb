class CustomersController < ApplicationController
  def index
    @customers = Crm::Customer.all
  end

  def new
    @customer_id = SecureRandom.uuid
  end

  def create
    create_customer(params[:customer_id], params[:name])
  rescue Crm::Customer::AlreadyRegistered
    flash[:notice] = "Customer was already registered."
    render "new"
  else
    redirect_to customers_path, notice: "Customer was successfully created."
  end

  private

  def create_customer(customer_id, name)
    command_bus.(create_customer_cmd(customer_id, name))
  end

  def create_customer_cmd(customer_id, name)
    Crm::RegisterCustomer.new(customer_id: customer_id, name: name)
  end
end