class CreateHistories < ActiveRecord::Migration
  def self.up
    create_table :histories do |t|
      t.integer :page_id, :default=>0, :null=>false
      t.integer :user_id, :default=>0
      t.integer :revision, :default=>0, :null=>false
      t.integer :content_id, :default=>0, :null=>false
      t.string :description, :default=>'', :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :histories
  end
end
