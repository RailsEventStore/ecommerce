class AddVatRateCodeToProduct < ActiveRecord::Migration[6.1]
  def change
    add_column :products, :vat_rate_code, :string
  end
end
