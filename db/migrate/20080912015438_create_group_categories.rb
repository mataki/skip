class CreateGroupCategories < ActiveRecord::Migration
  def self.up
    create_table :group_categories do |t|
      t.string :key,        :default => '', :null => false
      t.string :name,        :default => '', :null => false
      t.string :icon,        :default => '', :null => false
      t.string :description, :default => ''
      t.boolean :default,    :default => false, :null => false
      t.timestamps
    end
    add_index :group_categories, :key, :unique => true
    add_column :groups, :group_category_id, :integer

    Group.transaction do
      biz_category = GroupCategory.create!({ :key => "BIZ", :name => "ビジネス", :icon => "page_word", :description => "プロジェクト内など、業務で利用する場合に選択してください。" })
      life_category = GroupCategory.create!({ :key => "LIFE", :name => "ライフ", :icon => "group_gear", :description => "業務に直結しない会社内の活動で利用する場合に選択してください。", :default => true })
      off_category = GroupCategory.create!({ :key => "OFF", :name => "オフ", :icon => "ipod", :description => "趣味などざっくばらんな話題で利用する場合に選択してください。" })
      Group.all.each do |group|
        group.group_category_id = biz_category.id if group.category == 'BIZ'
        group.group_category_id = life_category.id if group.category == 'LIFE'
        group.group_category_id = off_category.id if group.category == 'OFF'
        group.save!
      end
    end
    remove_column :groups, :category
  end

  def self.down
    add_column :groups, :category, :string, :limit => 50, :default => '', :null => false
    remove_column :groups, :group_category_id
    drop_table :group_categories
  end
end
