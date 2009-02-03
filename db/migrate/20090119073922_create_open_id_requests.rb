class CreateOpenIdRequests < ActiveRecord::Migration
  def self.up
    create_table :open_id_requests do |t|
      t.string :token, :limit => 40
      t.text :parameters

      t.timestamps
    end

    add_index :open_id_requests, :token, :unique => true

    add_column :users, :last_authenticated_at, :datetime
  end

  def self.down
    drop_table :open_id_requests
    remove_column :users, :last_authenticated_at, :datetime
  end
end
