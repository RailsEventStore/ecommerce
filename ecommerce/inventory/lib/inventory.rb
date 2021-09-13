require_relative "../../../infra/lib/infra"
require_relative 'inventory/configuration'
require_relative 'inventory/commands/adjust_reservation'
require_relative 'inventory/commands/submit_reservation'
require_relative 'inventory/commands/cancel_reservation'
require_relative 'inventory/commands/complete_reservation'
require_relative 'inventory/commands/supply'
require_relative 'inventory/events/reservation_adjusted'
require_relative 'inventory/events/reservation_canceled'
require_relative 'inventory/events/reservation_completed'
require_relative 'inventory/events/reservation_submitted'
require_relative 'inventory/events/stock_level_changed'
require_relative 'inventory/events/stock_released'
require_relative 'inventory/events/stock_reserved'
require_relative 'inventory/reservation_service'
require_relative 'inventory/inventory_entry_service'
require_relative 'inventory/inventory_entry'
require_relative 'inventory/reservation'

module Inventory
end
