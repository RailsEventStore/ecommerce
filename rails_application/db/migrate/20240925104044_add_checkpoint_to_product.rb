class AddCheckpointToProduct < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :checkpoint, :string
  end
end
