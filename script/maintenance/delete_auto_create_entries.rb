delete_entry_ids = []
target_title = []
target_content = "(この投稿はシステムにより自動的に用意されました)"

target_title << "に招待しました"                # Ex: グループ：テストグループ00に招待しました
target_title << "】退会処理"                    # Ex: 【テストグループ00】退会処理
target_title << "参加申し込みをしました！"      # Ex: 参加申し込みをしました！
target_title << "ユーザー登録しました！"        # Ex: ユーザー登録しました！

BoardEntry.all.each do |e|
  target_title.each do |tt|
    if e.title.include?(tt) and e.contents.include?(target_content) and e.board_entry_comments.blank? and e.entry_trackbacks.blank?
      #未読状態のものを削除
      e.user_readings.each do |s|
        #puts s.read unless s.read
        s.destroy unless s.read
      end
      delete_entry_ids << (e.id.to_s + " : " + e.title)
      puts (e.id.to_s + " : " + e.title)
      e.destroy
    end
  end
end

open("tmp/delete_auto_create_entries_log.txt", "w") do |file|
  file.write "board_entries.id\n"
  delete_entry_ids.each do |info|
    file.write "#{info}\n"
  end
end
