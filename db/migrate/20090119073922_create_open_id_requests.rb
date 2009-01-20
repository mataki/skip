class CreateOpenIdRequests < ActiveRecord::Migration
  def self.up
#     create_table "open_id_associations", :force => true do |t|
#       t.column "server_url", :binary, :null => false
#       t.column "handle", :string, :null => false
#       t.column "secret", :binary, :null => false
#       t.column "issued", :integer, :null => false
#       t.column "lifetime", :integer, :null => false
#       t.column "assoc_type", :string, :null => false
#     end

#     create_table "open_id_nonces", :force => true do |t|
#       t.column :server_url, :string, :null => false
#       t.column :timestamp, :integer, :null => false
#       t.column :salt, :string, :null => false
#     end

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
#    drop_table "open_id_associations"
#    drop_table "open_id_nonces"
    remove_column :users, :last_authenticated_at, :datetime
  end
end
