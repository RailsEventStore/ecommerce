require 'yaml'
require 'json'

class MigrateYamlSerializedEventsToJson < ActiveRecord::Migration[5.2]
  def change
    RailsEventStoreActiveRecord::Event.all.each do |event|
      event.data     = JSON.dump(YAML.load(event.data))
      event.metadata = JSON.dump(YAML.load(event.metadata))
      event.save!
    end
  end
end
