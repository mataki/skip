atom_feed do |feed|
  feed.title("#{h(@title)} - #{h(Admin::Setting.abbr_app_title)}")
  unless @bookmarks.empty?
    feed.updated(@bookmarks.first.created_on)

    @bookmarks.each do |post|
      feed.entry(post, :url => post.escaped_url) do |entry|
        entry.title(h(post.title))
        bookmark_comment = post.bookmark_comments.last
        entry.content(h(bookmark_comment.comment), :type => "html")
        entry.author do |author|
          author.name(h(bookmark_comment.user.name))
        end
      end
    end
  end
end
