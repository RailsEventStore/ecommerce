Hanami.app.register_provider :repositories, namespace: true do
  prepare do
    register 'orders', Ecommerce::Repositories::Orders.new(target['persistence.rom'])
  end
end
