class CreateChapters < ActiveRecord::Migration
  def self.up
    create_table :chapters do |t|
      t.integer :content_id, :default=>0, :null=>false
      t.binary :data, :limit=>20.megabytes
      t.integer :order, :default=>0, :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :chapters
  end
end
