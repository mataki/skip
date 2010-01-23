require 'spec_helper'

describe Attachment do
  fixtures :contents
  fixtures :pages

  before(:each) do
    @uploaded_data = StringIO.new(File.read("spec/fixtures/data/at_small.png"))
    def @uploaded_data.original_filename; "at_small.png" end
    def @uploaded_data.content_type; "image/png" end

    @valid_attributes = {
      :uploaded_data => @uploaded_data,
      :user_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Attachment.create!(@valid_attributes)
  end

  describe "ファイルを添付するとき" do
    subject { pages(:our_page_1).attachments.build(@valid_attributes) }

    its(:display_name) { should == "at_small.png"}
    it { should be_valid }
  end

  describe "コンテンツタイプのチェックがかかること" do
    subject { pages(:our_page_1).attachments.build(@valid_attributes) }

    it "image/gifの場合検証に失敗すること" do
      subject.content_type = "image/gif"
      should_not be_valid
    end

    it "htmlファイルの場合、検証に失敗すること" do
      subject.filename, subject.content_type = "foo.html", "text/html"
      should_not be_valid
    end
  end

  describe "Quota Validation(システム全体)" do
    before do
      @attachment = Attachment.new(@valid_attributes)
      @attachment.stub!(:size).and_return(20.gigabytes+1)
      @attachment.save
    end
    it{ @attachment.should have(1).errors_on(:size) }
  end

  describe "Quota Validation(個々のファイル)" do
    before do
      File.should_receive(:size).with(kind_of(String)).and_return(10.megabytes + 1)
    end

    subject do      uploaded_data = StringIO.new(File.read("spec/fixtures/data/at_small.png"))
      def uploaded_data.original_filename; "at_small.png" end
      def uploaded_data.content_type; "image/png" end

      pages(:our_page_1).attachments.build(:uploaded_data => uploaded_data)
    end

    it{ should have(1).errors_on(:size) }
  end

end
