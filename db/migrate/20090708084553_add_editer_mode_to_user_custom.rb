class AddEditerModeToUserCustom < ActiveRecord::Migration
  def self.up
    add_column :user_customs, :editor_mode, :string, :default => "richtext", :null => false
  end

  def self.down
    remove_column :user_customs, :editor_mode
  end
end
