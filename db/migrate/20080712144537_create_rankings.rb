class CreateRankings < ActiveRecord::Migration
  def self.up
    create_table :rankings do |t|
      t.string "url", :null => false
      t.string "title", :null => false
      t.string "author", :null => true
      t.string "author_url", :null => true
      t.date "extracted_on", :null => false
      t.integer "amount", :null => true
      t.string "contents_type", :null => false
      t.timestamps
    end
    add_index(:rankings, :url)
    add_index(:rankings, :extracted_on)
    add_index(:rankings, :contents_type)
  end

  def self.down
    drop_table :rankings
  end
end
