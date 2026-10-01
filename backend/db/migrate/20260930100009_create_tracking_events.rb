class CreateTrackingEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :tracking_events do |t|
      t.references :consignment, null: false, foreign_key: true, index: false
      t.references :user, foreign_key: true # who caused it; NULL for system events
      t.string :event_type, null: false
      t.string :status, null: false
      t.datetime :occurred_at, null: false
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.jsonb :metadata, null: false, default: {}
      # Append-only: created_at but no updated_at, because rows are never updated.
      t.datetime :created_at, null: false

      # Serves the timeline query: WHERE consignment_id = ? ORDER BY occurred_at
      t.index %i[consignment_id occurred_at]

      t.check_constraint "event_type IN ('status_changed', 'driver_reassigned')",
        name: "tracking_events_event_type_valid"
      t.check_constraint "status IN ('booked', 'allocated', 'picked_up', 'in_transit', 'delivered')",
        name: "tracking_events_status_valid"
      t.check_constraint "(latitude IS NULL) = (longitude IS NULL)",
        name: "tracking_events_coordinates_paired"
      t.check_constraint "latitude BETWEEN -90 AND 90", name: "tracking_events_latitude_range"
      t.check_constraint "longitude BETWEEN -180 AND 180", name: "tracking_events_longitude_range"
    end
  end
end
