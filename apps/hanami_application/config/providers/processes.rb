# frozen_string_literal: true

Hanami.app.register_provider :processes do
  start do
    target.start :command_bus
    target.start :read_models

    HanamiApplication::Processes::OrderFulfillment
      .new(target["command_bus"])
      .subscribe(target["event_store"])
  end
end
