require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe History do
  fixtures :pages
  fixtures :contents
  fixtures :chapters

  before(:each) do
    @valid_attributes = {
      :page => pages(:our_page_1),
      :user_id => "1",
      :revision => "1",
      :content_id => "1"
    }
  end

  describe "save" do
    before do
      @page = pages(:our_page_1)
      @page.edit(contents(:one), mock_model(User))
      @page.save!
      Time.should_receive(:now).at_least(:once).and_return(@mock_t = Time.local(2007,12,31, 00, 00, 00))
      History.create!(@valid_attributes) do |h|
        h.page.reload
        h.content = contents(:two)
      end
    end

    it "pageのtimestampを更新すること" do
      @page.reload.updated_at.should == @mock_t
    end

    it "pageの最終更新者IDが変更されていること" do
      lambda{ @page.reload }.should change(@page, :last_modified_user_id)
    end
  end

  describe ".find_all_by_head_content" do

    def create_history_with_content(page, content)
      new_content = Content.new
      new_content.chapters.build(:data=>content)
      History.create(:content => new_content,
                     :page => page,
                     :user => mock_model(User),
                     :revision => History.count.succ)
    end

    before do
      @page = pages(:our_page_1)
      @history = create_history_with_content(@page, "hoge hoge hoge")
    end
=begin
検索が必要になったときに再度テスト
    it "('hoge').should == [@history]" do
      History.find_all_by_head_content("hoge").should == [@history]
    end

    it "新しい履歴ができると、以前の語ではマッチしなくなること" do
      @history = create_history_with_content(@page, "fuga fuga fuga")
      History.find_all_by_head_content("hoge").should == []
    end
=end
  end

end
