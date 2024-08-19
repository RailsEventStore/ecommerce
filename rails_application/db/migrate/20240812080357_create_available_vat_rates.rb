class CreateAvailableVatRates < ActiveRecord::Migration[7.0]
  def change
    create_table :available_vat_rates do |t|
      t.uuid :uid, null: false
      t.string :code, null: false
      t.decimal :rate, null: false

      t.timestamps
    end
  end
end
