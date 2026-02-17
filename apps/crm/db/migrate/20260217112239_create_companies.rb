class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.uuid :uid, null: false
      t.string :name, null: false
      t.string :linkedin_url

      t.timestamps
    end
    add_index :companies, :uid, unique: true
  end
end
