module Client
  class ClientsController < BaseController

    skip_before_action :ensure_logged_in, only: [:index, :login, :logout]

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
        if not correct_password?(client_id, password)
          flash[:alert] = "Incorrect password"
          redirect_to clients_path
          return
        end
        cookies[:client_id] = client_id
      else
        cookies[:client_id] = client_id
      end
      redirect_to client_orders_path
    end

    def logout
      cookies.delete(:client_id)
      redirect_to clients_path
    end

    private

    def correct_password?(client_id, password)
      password_hash = Digest::SHA256.hexdigest(password)
      account = ClientAuthentication::Account.find_by(client_id: client_id)
      password_hash.eql?(account.password)
    end
  end
end
