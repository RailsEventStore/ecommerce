class CatalogController < ApplicationController
  def index
    products = PublicCatalog::Product.all
    prepend_view_path Rails.root.join("app", "public", "read_models")
    render template: "public_catalog/index", locals: { products: products }
  end
end