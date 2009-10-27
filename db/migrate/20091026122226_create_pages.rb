class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.integer :last_modified_user_id, :default=>0, :null=>false
      t.string :title, :null=>false
      t.string :format_type, :limit => 16, :default=>'html', :null=>false
      t.datetime :deleted_at
      t.integer :lock_version, :default =>0
      t.timestamps
    end

  end

  def self.down
    drop_table :pages
  end
end
