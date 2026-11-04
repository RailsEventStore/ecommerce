module Orders
  class FreeProductSavingRenderer
    def self.call(saving)
      ApplicationController.render(
        partial: "orders/free_product_saving",
        locals: { saving: saving, colspan: 5 }
      ).rstrip
    end
  end
end
