class Login < Arbre::Component
  def self.build(view_context)
    new(Arbre::Context.new(nil, view_context)).build
  end

  def build(attributes = {})
    super(attributes)
    clients = ClientOrders::Client.all
    div class: "max-w-6xl mx-auto py-6 sm:px-6 lg:px-8" do
      safe_join([
        text_node(form_tag("login", method: :post)),
        div do
          safe_join([
            label_tag(:name),
            select_tag(:client_id, options_from_collection_for_select(clients, :uid, :name), id: "client", class: "mt-1 focus:ring-blue-500 focus:border-blue-500 block shadow-sm sm:text-sm border-gray-300 rounded-md"),
            label_tag(:password),
            password_field_tag(:password, nil, class: "mt-1 focus:ring-blue-500 focus:border-blue-500 block shadow-sm sm:text-sm border-gray-300 rounded-md"),
            button_tag('Login', class: "mt-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded")
          ])
        end,
        para("Since this is a demo application and you dont't know the password. You can log in by leaving the password field empty", class: "font-bold py-2"),
      ])
    end
  end
end
