Hanami.app.register_provider :persistence, namespace: true do
  prepare do
     require 'rom-changeset'
     require 'rom/core'
     require 'rom/sql'
     require 'rom-repository'

     config =
       ROM::Configuration.new(
         :sql, target['settings'].database_url
       )

     config.auto_registration(
       target.root.join('app/persistence'),
       namespace: 'Ecommerce::Persistence::Relations'
     )

     register 'config', config
     register 'db', config.gateways[:default].connection
     register 'rom', ROM.container(config)
     register 'transaction', Infra::Transaction.new(container: config)
  end
end
