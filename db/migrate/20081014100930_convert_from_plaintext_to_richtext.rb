# プレーンテキストからリッチテキストへの強制変換
class ConvertFromPlaintextToRichtext < ActiveRecord::Migration
  def self.up
    BoardEntry.find(:all).each do |entry|
      if entry.editor_mode == "plaintext"
        entry.contents = "<pre>#{entry.contents}</pre>"
        entry.editor_mode = "richtext"
        entry.save(false)
      end
    end
  end

  def self.down
    # N/A
  end
end
