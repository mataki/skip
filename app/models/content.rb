class Content < ActiveRecord::Base
  has_many :chapters, :dependent => :destroy

  def data
    self.chapters.all.collect {|c| c.data }.to_s
  end
end
