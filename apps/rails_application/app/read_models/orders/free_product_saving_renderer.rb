module Orders
  class FreeProductSavingRenderer
    def call(saving)
      ApplicationController.render(
        partial: "orders/free_product_saving",
        locals: { saving: saving }
      ).rstrip
    end
  end
end
