class CreateClients < ActiveRecord::Migration[6.1]
  def change
    create_table :clients do |t|
      t.uuid :uid
      t.string :name

      t.timestamps
    end
  end
end
