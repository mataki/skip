class AddTimestampsToShareFiles < ActiveRecord::Migration
  def self.up
    add_timestamps(:share_files)
    now = Time.now
    ActiveRecord::Base.connection.execute("update share_files set created_at = '#{now.to_formatted_s(:db)}', updated_at = '#{now.to_formatted_s(:db)}'")
  end

  def self.down
    remove_timestamps(:share_files)
  end
end
