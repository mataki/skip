class RemoveDataFromContent < ActiveRecord::Migration
  def self.up
    Content.all.each do |c|
      c.chapters.build({:data=>c.data})
      c.save
    end

    remove_column :contents, :data
  end

  def self.down
    add_column :contents, :data, :binary, :limit=>20.megabytes
  end
end
