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

class Content < ActiveRecord::Base
  has_many :chapters, :dependent => :destroy
end

class Chapter < ActiveRecord::Base
  belongs_to :content

  validates_presence_of :data
end
