class DbFile < ActiveRecord::Migration
  def self.up
    create_table :db_files do |t|
      t.column :data, :binary, :null => false, :default => '', :limit => 10.megabytes
    end
  end

  def self.down
    drop_table :db_files
  end
end
