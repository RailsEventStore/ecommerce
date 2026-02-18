class DashboardController < ApplicationController
  def show
    @contacts_count = Contacts.all.size
    @companies_count = Companies.all.size
    @deals_count = Deals.all.size
    @pipelines_count = Pipelines.all.size
    @recent_deals = Deals.all.last(5)
  end
end
