class CreateClientInboxMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :client_inbox_messages, id: :uuid do |t|
      t.uuid :client_uid, null: false, index: true
      t.string :title, null: false
      t.boolean :read, default: false, null: false
      t.timestamps
    end
  end
end
