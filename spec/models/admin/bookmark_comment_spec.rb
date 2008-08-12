require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BookmarkComment do
  before(:each) do
    @bookmark_comment = Admin::BookmarkComment.new
  end

  it "should be valid" do
    @bookmark_comment.should be_valid
  end
end
