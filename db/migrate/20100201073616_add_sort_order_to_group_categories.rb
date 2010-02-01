class AddSortOrderToGroupCategories < ActiveRecord::Migration
  def self.up
    add_column :group_categories, :sort_order, :integer, :default => 0
    GroupCategory.all.each do |gc|
      gc.update_attribute(:sort_order, gc.id * 10)
    end

    add_index :group_categories, :sort_order
  end

  def self.down
    remove_column :group_categories, :sort_order
  end

  class ::GroupCategory < ActiveRecord::Base
  end
end
