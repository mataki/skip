class RemoveProfiles < ActiveRecord::Migration
  def self.up
    drop_table :user_profiles
    remove_column :site_counts, :profile_users
  end

  def self.down
    add_column :site_counts, :profile_users, :integer, :default => 0
    create_table "user_profiles", :force => true do |t|
      t.integer "user_id",                          :null => false
      t.integer "gender_type",       :limit => 2
      t.integer "join_year"
      t.integer "birth_month",       :limit => 1
      t.integer "birth_day",         :limit => 1
      t.integer "blood_type",        :limit => 1
      t.integer "hometown",          :limit => 2
      t.string  "alma_mater",        :limit => 100
      t.integer "address_1",         :limit => 2
      t.string  "address_2",         :limit => 100
      t.text    "hobby"
      t.text    "introduction"
      t.boolean "disclosure",                       :null => false
      t.string  "extension",         :limit => 100
      t.text    "self_introduction"
    end
  end
end
