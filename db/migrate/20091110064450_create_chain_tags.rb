class CreateChainTags < ActiveRecord::Migration
  def self.up
    create_table :chain_tags do |t|
      t.references :chain, :null => false
      t.references :tag, :null => false
      t.timestamps
    end

    add_index :chain_tags, :chain_id
    add_index :chain_tags, :tag_id
  end

  def self.down
    drop_table :chain_tags
  end
end
