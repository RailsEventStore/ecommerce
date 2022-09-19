module PublicOffer
  class Product < ApplicationRecord
    self.table_name = "public_offer_products"
  end

  class ProductsList < Arbre::Component

    def self.build(view_context, client_id)
      new(Arbre::Context.new(nil, view_context)).build(Product.all)
    end

    def build(products, attributes = {})
      super(attributes)

      div class: "max-w-6xl mx-auto py-6 sm:px-6 lg:px-8" do
        products_table(products)
      end

    end

    private


    def products_table(products)
      if products.count > 0
        table class: "w-full" do
          thead do
            tr class: "border-t" do
              th class: "text-left py-2" do
                "Name"
              end
              th class: "text-right py-2" do
                "Price"
              end
            end
          end
          tbody do
            products.each do |product|
              tr class: "border-t" do

                td class: "py-2 text-left" do
                  product.name
                end
                td class: "py-2 text-right" do
                  number_to_currency(product.price)
                end
              end
            end
          end
        end
      else
        para do
          "No products to display."
        end
      end
    end
  end

  class Configuration
    def initialize(cqrs)
      @read_model = SingleTableReadModel.new(cqrs, Product, :product_id)
    end

    def call
      @read_model.subscribe_create(ProductCatalog::ProductRegistered)
      @read_model.copy(ProductCatalog::ProductNamed,       :name)
      @read_model.copy(Pricing::PriceSet,                  :price)
    end
  end
end