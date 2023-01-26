module Client
  class ClientsController < ApplicationController
    layout "client_panel"

    def index
      if cookies[:client_id]
        redirect_to client_orders_path
      else
        render html: Login.build(view_context), layout: true
      end
    end

    def login
      password = params[:password]
      client_id = params[:client_id]
      if password.present?
        customer = Customers::Customer.find(client_id)
        command_bus.(
          Authentication::Login.new(
            account_id: customer.account_id,
            password: password
          )
        )
      end
      cookies[:client_id] = client_id
      redirect_to client_orders_path
    rescue Authentication::Account::WrongPassword
      flash[:alert] = "Incorrect password"
      redirect_to clients_path
    end

    def logout
      cookies.delete(:client_id)
      redirect_to clients_path
    end
  end
end
