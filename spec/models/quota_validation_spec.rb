require File.dirname(__FILE__) + '/../spec_helper'

class ValidateFileClass
  include QuotaValidation

  attr_accessor :file
end

describe QuotaValidation do
  before do
    @vf = mock_model_class
    @muf = mock_uploaed_file
  end
  describe "#valid_size_of_file" do
    describe "ファイルサイズが0の場合" do
      it "エラーが追加されること" do
        @muf.stub!(:size).and_return(0)
        @vf.errors.should_receive(:add_to_base).with('Nonexistent or empty files are not accepted for uploading.')
        @vf.valid_size_of_file(@muf)
      end
    end
    describe "ファイルサイズが最大値を超えている場合" do
      it "エラーが追加されること" do
        @muf.stub!(:size).and_return(SkipEmbedded::InitialSettings['max_share_file_size'].to_i + 100)
        @vf.errors.should_receive(:add_to_base).with("Files larger than #{SkipEmbedded::InitialSettings['max_share_file_size'].to_i/1.megabyte}MBytes are not permitted.")
        @vf.valid_size_of_file(@muf)
      end
    end
  end

  describe "#valid_max_size_of_system_of_file" do
    describe "ファイルサイズがオーナーの最大許可容量を超えている場合" do
      it "エラーが追加されること" do
        @muf.stub!(:size).and_return(101)
        QuotaValidation::FileSizeCounter.should_receive(:per_system).and_return(SkipEmbedded::InitialSettings['max_share_file_size_of_system'].to_i - 100)
        @vf.errors.should_receive(:add_to_base).with('Upload denied due to excess of system wide shared files disk capacity.')
        @vf.valid_max_size_of_system_of_file(@muf)
      end
    end
  end
  describe QuotaValidation::FileSizeCounter do
    describe ".per_owner" do
      before do
        ShareFile.should_receive(:total_share_file_size).and_return(100)
      end
      it "ファイルサイズを返す" do
        QuotaValidation::FileSizeCounter.per_owner(@owner_symbol).should == 100
      end
    end
    describe ".per_system" do
      before do
        Dir.should_receive(:glob).with("#{SkipEmbedded::InitialSettings['share_file_path']}/**/*").and_return(["a", "a"])
        file = mock('file')
        file.stub!(:size).and_return(100)
        File.should_receive(:stat).with('a').at_least(:once).and_return(file)
      end
      it "ファイルサイズを返す" do
        QuotaValidation::FileSizeCounter.per_system.should == 200
      end
    end
  end

  def mock_model_class
    errors = mock('errors')
    errors.stub!(:add_to_base)

    vf = ValidateFileClass.new
    vf.stub!(:errors).and_return(errors)
    vf
  end
end
