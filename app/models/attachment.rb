class Attachment < ActiveRecord::Base
  include ::QuotaValidation
  include ::SkipEmbedded::ValidationsFile

  QUOTA_EACH = QuotaValidation.lookup_setting(self,:each)

  has_attachment :storage => :db_file,
                 :size => 1..QuotaValidation.lookup_setting(self, :each),
                 :processor => :none

  attr_accessible :uploaded_data, :user_id, :db_file_id

  attachment_options.delete(:size) # エラーメッセージカスタマイズのため、自分でバリデーションをかける

  validates_inclusion_of :size, :in => 1..QUOTA_EACH, :message =>
    "#{QUOTA_EACH.to_i/1.megabyte}Mバイト以上のファイルはアップロードできません。"
  validates_quota_of :size, :system, :message =>
    "のシステム全体における保存領域の利用容量が最大値を越えてしまうためアップロードできません。"

  belongs_to :user
  belongs_to :page

  validates_presence_of :display_name
  validates_as_attachment

  def filename=(new_name)
    super
    self.display_name = new_name
  end

  private
  def validate_on_create
    adapter = ValidationsFileAdapter.new(self)

    valid_extension_of_file(adapter)
    valid_content_type_of_file(adapter)
  end

end
