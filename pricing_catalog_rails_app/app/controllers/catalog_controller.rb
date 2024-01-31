class CatalogController < ApplicationController
  def index
    @products = PublicCatalog::Product.all
    prepend_view_path Rails.root.join("app", "read_models")
    render template: "public_catalog/index"
  end
end