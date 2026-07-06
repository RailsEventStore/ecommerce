class RenameHomeTimelineEdgesToFollows < ActiveRecord::Migration[8.1]
  def change
    rename_table :home_timeline_edges, :home_timeline_follows
  end
end
