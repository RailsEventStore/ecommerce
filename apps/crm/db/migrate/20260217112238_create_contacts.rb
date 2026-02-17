class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.uuid :uid, null: false
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :linkedin_url

      t.timestamps
    end
    add_index :contacts, :uid, unique: true
  end
end
