class AddDefaultPublicationTypeToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :default_publication_type, :string, :null => false, :default => 'private'
  end

  def self.down
    remove_column :groups, :default_publication_type
  end
end
