class StoresController < ApplicationController
  def switch
    cookies[:current_store_id] = params[:store_id]
    redirect_back(fallback_location: root_path)
  end
end
