class CreateFirstPage < ActiveRecord::Migration
  def self.up
    Page.create!(:title=>"トップページ")
  end

  def self.down
  end
end
