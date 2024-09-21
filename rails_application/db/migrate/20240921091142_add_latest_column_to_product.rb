class AddLatestColumnToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :latest, :boolean, default: true
  end
end
