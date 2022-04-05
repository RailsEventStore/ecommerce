# frozen_string_literal: true

Crm::Container.register_provider :subscriptions do |container|
  prepare do
    pp 'CRM subscriptions prepared'
  end

  start do
    cqrs = container['application.cqrs']
    repo = container['repositories.customers']

    pp 'CRM subscriptions started'
    cqrs.subscribe(
      -> (event) { repo.create(id: event.data.fetch(:customer_id), name: event.data.fetch(:name)) },
      [Crm::CustomerRegistered]
    )

    cqrs.subscribe(
      -> (event) { repo.find(event.data.fetch(:customer_id)).update(vip: true) },
      [Crm::CustomerPromotedToVip]
    )
  end
end
