module PublicOffer
  class ProductsList < Arbre::Component

    def self.build(view_context)
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
                  if product.lowest_recent_price_lower_from_current?
                    span title: "Lowest recent price: #{number_to_currency(product.lowest_recent_price)}",
                      id: "lowest-price-info-#{product.id}" do
                      "ℹ️"
                    end
                  end

                  span do
                    number_to_currency(product.price)
                  end
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
    def initialize(event_store)
      @read_model = SingleTableReadModel.new(event_store, Product, :product_id)
      @event_store = event_store
    end

    def call
      @read_model.subscribe_create(ProductCatalog::ProductRegistered)
      @read_model.subscribe_copy(ProductCatalog::ProductNamed, :name)
      @read_model.subscribe_copy(Pricing::PriceSet, :price)
      @event_store.subscribe(RegisterLowestPrice, to: [Pricing::PriceSet])
    end
  end
end
