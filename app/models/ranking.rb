class Ranking < ActiveRecord::Base
  named_scope :by_contents_type, proc{|contents_type| {:conditions => {:contents_type => contents_type.to_s}} }
end
