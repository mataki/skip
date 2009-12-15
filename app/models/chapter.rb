class Chapter < ActiveRecord::Base
  belongs_to :content
  validates_presence_of :data

end
