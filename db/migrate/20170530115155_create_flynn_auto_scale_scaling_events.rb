class CreateFlynnAutoScaleScalingEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :flynn_auto_scale_scaling_events do |t|
      t.string :event_type
      t.integer :instances

      t.timestamps
    end
  end
end
