module Client
  class OrdersController < ApplicationController

    layout 'client_panel'

    def index
      render html: ClientOrders::OrdersList.build(view_context, cookies[:client_id]), layout: true
    end

  end
end
