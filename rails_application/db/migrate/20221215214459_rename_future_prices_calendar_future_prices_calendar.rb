class RenameFuturePricesCalendarFuturePricesCalendar < ActiveRecord::Migration[7.0]
  def change
    rename_column :products, :future_prices_calendar, :current_prices_calendar
  end
end
