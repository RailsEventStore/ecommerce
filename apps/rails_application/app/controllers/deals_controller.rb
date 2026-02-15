class DealsController < ApplicationController
  def index
    @deals = Deals.deals_for_store(current_store_id)
  end
end
