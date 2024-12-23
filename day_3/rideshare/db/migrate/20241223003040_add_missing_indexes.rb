class AddMissingIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction! # ! PostgreSQL only ! run concurrently, NO lock table writes

  def change
    # MissingIndexChecker fail TripRequest trip associated model should have proper unique index in the database
    # MissingIndexChecker fail TripRequest vehicle_reservations associated model should have proper index in the database
    # MissingIndexChecker fail Trip trip_positions associated model should have proper index in the database
    
    add_index(:trip_request, :store_id) # basic
    
    add_index(:addresses, [:addressable_type, :addressable_id]) # polymorphic
    
    # has_one :title_track, -> { where(number: 1) }, class: Track
    add_index(:tracks, :album_id, where: 'number = 1', name: index_title_tracks_on_album_id) # partial
  end
end
