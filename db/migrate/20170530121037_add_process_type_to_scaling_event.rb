class AddProcessTypeToScalingEvent < ActiveRecord::Migration[5.0]
  def change
    add_column :scaling_events, :process_type, :string
  end
end
