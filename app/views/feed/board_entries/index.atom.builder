atom_feed do |feed|
  feed.title("#{h(@title)} - #{h(Admin::Setting.abbr_app_title)}")
  unless @entries.empty?
    feed.updated(@entries.first.created_on)

    @entries.each do |post|
      feed.entry(post, :url => entry_link_to(post)) do |entry|
        entry.title(h(post.title))
        entry.content(show_contents(post), :type => "html")
        entry.author do |author|
          author.name(h(post.user.name))
        end
      end
    end
  end
end
