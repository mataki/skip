atom_feed(:root_url => root_url, :url => request.url, :id => root_url) do |feed|
  feed.title("#{h(@title)} - #{h(Admin::Setting.abbr_app_title)}")
  unless @entries.empty?
    feed.updated(@entries.first.created_on)

    @entries.each do |post|
      feed.entry(
        post,
        :url => url_for(:controller => '/board_entries', :action => 'forward', :id => post.id, :only_path => false),
        :published => post.created_on,
        :updated => post.last_updated
      ) do |entry|
        entry.title(h(post.title))
        entry.content(show_contents(post), :type => "html")
        entry.author do |author|
          author.name(h(post.user.name))
        end
      end
    end
  end
end
