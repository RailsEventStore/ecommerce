class AddArchivedToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :archived, :boolean, default: false, null: false
  end
end
