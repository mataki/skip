# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

class CreateUserProfileCustomizeTables < ActiveRecord::Migration
  def self.up
    create_table :user_profile_master_categories do |t|
      t.string  :name,       :default => "", :null => false
      t.integer :sort_order, :default => 0,  :null => false
      t.text    :description
      t.timestamps
    end

    create_table :user_profile_masters do |t|
      t.references :user_profile_master_category
      t.string     :name,       :default => "",    :null => false
      t.string     :input_type, :default => "",    :null => false
      t.boolean    :required,   :default => false, :null => false
      t.integer    :sort_order, :default => 0,     :null => false
      t.text       :option_values
      t.text       :description
      t.timestamps
    end
    add_index :user_profile_masters, :user_profile_master_category_id

    create_table :user_profile_values do |t|
      t.references :user
      t.references :user_profile_master
      t.text       :value
      t.timestamps
    end
    add_index :user_profile_values, :user_id
    add_index :user_profile_values, :user_profile_master_id
  end

  def self.down
    drop_table :user_profile_master_categories
    drop_table :user_profile_masters
    drop_table :user_profile_values
  end
end
