class MoveAttachmentImageToShareFile < ActiveRecord::Migration
  def self.up
    say_with_time 'Updating share_files...' do
      MoveAttachmentImage.execute
    end
  end

  def self.down
    # 元に戻せない変更なので
    raise IrreversibleMigration
  end
end
