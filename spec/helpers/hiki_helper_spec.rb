describe HikiHelper, '#parse_permalink' do
  before do
    helper.stub!(:form_authenticity_token)
  end
  describe '[file:foo\nbar]のように共有ファイルへのリンク中に改行コードを含む場合' do
    it 'Routing Errorとならないこと' do
      lambda do
        helper.send(:parse_permalink, "[file:foo\r\nbar]", 'uid:alice')
      end.should_not raise_error
    end
    it '改行コードが取り除かれること' do
      helper.send(:parse_permalink, "[file:foo\r\nbar]", 'uid:alice').should == "<a href=\"http://test.host/user/alice/files/foobar\">file:foo\r\nbar</a>"
    end
  end
end
