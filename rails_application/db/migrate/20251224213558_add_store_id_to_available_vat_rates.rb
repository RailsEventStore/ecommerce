class AddStoreIdToAvailableVatRates < ActiveRecord::Migration[8.0]
  def change
    add_column :available_vat_rates, :store_id, :uuid
  end
end
