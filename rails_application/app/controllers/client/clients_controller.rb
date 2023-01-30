module Client
  class ClientsController < ApplicationController
    layout "client_panel"

    WrongPassword = Class.new(StandardError)

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
        raise WrongPassword unless correct_password?(client_id, password)
        cookies[:client_id] = client_id
      else
        cookies[:client_id] = client_id
      end
      redirect_to client_orders_path
    rescue WrongPassword
      flash[:alert] = "Incorrect password"
      redirect_to clients_path
    end

    def logout
      cookies.delete(:client_id)
      redirect_to clients_path
    end


    def correct_password?(client_id, password)
      password_hash = Digest::SHA256.hexdigest(password)
      account = ClientAuthentication::Account.find_by(client_id: client_id)
      password_hash.eql?(account.password)
    end
  end
end
