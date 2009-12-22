class Chapter < ActiveRecord::Base
  belongs_to :content
  acts_as_list :scope => :content

  validates_presence_of :data
  has_many :attachments
end
