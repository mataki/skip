class CreateRankings < ActiveRecord::Migration
  def self.up
    create_table :rankings do |t|
      t.string "url", :null => false
      t.string "title", :null => false
      t.string "author", :null => true
      t.string "author_url", :null => true
      t.date "extracted_on", :null => false
      t.integer "amaount", :null => true
      t.integer "contents_type_id", :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :rankings
  end
end
