# frozen_string_literal: true

Hanami.app.register_provider :processes do
  start do
    target.start :command_bus
    target.start :read_models

    HanamiApplication::Processes::OrderAcceptance
      .new(target["command_bus"], target["read_models.orders"])
      .subscribe(target["event_store"])

    HanamiApplication::Processes::OrderFulfillment
      .new(target["command_bus"])
      .subscribe(target["event_store"])
  end
end
