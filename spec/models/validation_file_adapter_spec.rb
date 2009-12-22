require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'validations_file_adapter'

describe ValidationsFileAdapter do
  describe "foo.png @ image/png" do
    subject do
      record = mock("record")
      record.stub!(:filename => "foo.png", :content_type => "image/png", :size => 12345, :display_name => "ふー.png")

      ValidationsFileAdapter.new(record)
    end
    it("size"){ subject.size.should == 12345}
    it("content_type"){ subject.content_type.should == "image/png" }
    it("original_filename"){ subject.original_filename.should == "ふー.png" }
  end
end
