atom_feed(:root_url => root_url, :url => request.url, :id => root_url) do |feed|
  feed.title("#{h(@title)} - #{h(Admin::Setting.abbr_app_title)}")
  unless @bookmarks.empty?
    feed.updated(@bookmarks.first.created_on)

    @bookmarks.each do |post|
      feed.entry(
        post,
        :url => post.escaped_url,
        :published => post.created_on,
        :updated => post.bookmark_comments.last.updated_on
      ) do |entry|
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
