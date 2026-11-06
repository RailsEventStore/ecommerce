module Orders
  class SubmitButtonRenderer
    def self.call(order_id)
      if OrderLine.exists?(order_uid: order_id)
        ApplicationController.helpers.primary_form_action_button { "Submit Order" }
      else
        ""
      end
    end
  end
end
