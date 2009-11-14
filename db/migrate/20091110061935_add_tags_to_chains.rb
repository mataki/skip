class AddTagsToChains < ActiveRecord::Migration
  def self.up
    add_column :chains, :tags_as_s, :string
  end

  def self.down
    remove_column :chains, :tags
  end
end
