class Ranking < ActiveRecord::Base
  named_scope :by_contents_type, proc{|contents_type| {:conditions => {:contents_type => contents_type.to_s}} }
  named_scope :max_amount_by_url, {:select => 'id, url, title, max(extracted_on) as extracted_on, amount', :group => :url}
  named_scope :top_10, {:order => 'amount desc', :limit => 10}

  def self.all(contents_type)
    # TODO 通常のallメソッドと名前かぶるの変える
    by_contents_type(contents_type).max_amount_by_url.top_10
  end

  def self.monthly(contents_type, year, month)
  end
end
