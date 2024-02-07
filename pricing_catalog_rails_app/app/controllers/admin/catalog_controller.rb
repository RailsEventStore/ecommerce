class Admin::CatalogController < ApplicationController
  def index
    products = AdminCatalog::Product.all
    prepend_view_path Rails.root.join("app", "admin", "read_models")
    render template: "admin_catalog/index",
           locals: { products: products, new_product: AdminCatalog::Product.new }
  end

  def create
    RegisterProduct.new.call(
      params[:admin_catalog_product][:name],
      params[:admin_catalog_product][:price]
    )
    redirect_to admin_root_path
  end
end