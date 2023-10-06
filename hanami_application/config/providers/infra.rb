Hanami.app.register_provider :infra, namespace: true do
  prepare do
    require 'infra'

    register "aggregate_root_repo", Infra::AggregateRootRepository.new(
      target["event_store.client"]
    )
  end
end