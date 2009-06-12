class SetDefaultValueToStatusOnUser < ActiveRecord::Migration
  def self.up
    change_column_default(:users, :status, "UNUSED")
  end

  def self.down
    # デフォルト値をNULLにするのは、RailsではサポートしておらずSQLを書く必要があり
    # そこまでしてやるひつようもないので、何もしない
  end
end
