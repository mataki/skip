class ConvertBookmarkOfUserFromBookmarksToChains < ActiveRecord::Migration
  def self.up
    user_type_bookmarks = []
    Bookmark.all.each { |bookmark| user_type_bookmarks << bookmark if bookmark.is_type_user? }
    ActiveRecord::Base.transaction do
      user_type_bookmarks.each do |bookmark|
        if bookmark.bookmark_comments_count > 0
          uid = bookmark.url.slice(/^\/user\/(.*)/, 1)
          to_user = User.find_by_uid(uid)
          if to_user
            bookmark.bookmark_comments.each do |bookmark_comment|
              from_user = bookmark_comment.user
              chain = to_user.against_chains.find_by_from_user_id(from_user.id)
              result = ""
              if chain
                # 既に紹介文が存在するケースでは紹介文の先頭行にブックマークコメントを挿入
                chain.comment = "<p>#{bookmark_comment.comment}</p>#{chain.comment}"
                result << "update successful"
              else
                # 紹介文が存在しないケースでは新規作成
                chain = to_user.against_chains.build :from_user => from_user, :comment => "<p>#{bookmark_comment.comment}</p>"
                result << "create successful"
              end
              chain.tags_as_s = bookmark_comment.bookmark_comment_tags.map{|t|t.tag.name}.join(',')
              chain.save!
              puts "#{result} :chain_id => #{chain.id} by :bookmark_id => #{bookmark.id}"
            end
          else
            # ブックマークされたユーザが存在しない
            puts "skipeed :bookmark_id => #{bookmark.id}, :url => #{bookmark.url} because uid:#{uid} not found."
          end
        else
          # ブックマークコメントがゼロ件
          puts "skipped :bookmark_id => #{bookmark.id}, :url => #{bookmark.url} because bookmark_comments_count is zero."
        end
      end
      user_type_bookmarks.each do |bookmark|
        bookmark.destroy # bookmark_comments及び、bookmark_comment_tagsも同時に削除される
        puts "deleted :id => #{bookmark.id}, :url => #{bookmark.url}"
      end
    end
  end

  def self.down
    raise IrreversibleMigration
  end

  class ::Bookmark < ActiveRecord::Base
    has_many :bookmark_comments, :dependent => :destroy
    has_many :popular_bookmarks, :dependent => :destroy
    def is_type_user?
      self.url.index("/user/") == 0
    end
  end

  class ::BookmarkComment < ActiveRecord::Base
    belongs_to :user
    has_many :bookmark_comment_tags, :dependent => :destroy
  end
end
