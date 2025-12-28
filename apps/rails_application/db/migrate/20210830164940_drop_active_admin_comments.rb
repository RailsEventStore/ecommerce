class DropActiveAdminComments < ActiveRecord::Migration[6.1]
  def change
    drop_table "active_admin_comments"
  end
end
