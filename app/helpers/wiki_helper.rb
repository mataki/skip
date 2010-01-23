module WikiHelper
  def wiki_tab_menu_source page
    tab_menu_source = []
    # KuroText
    tab_menu_source << {:label => _("Content"), :options => wiki_path(page.title)}
    # KuroText
    tab_menu_source << {:label => _("History"), :options => wiki_histories_path(page.title)}
    tab_menu_source
  end

  def generate_wiki_topics_str page
    link_str = []
    # First Page
    link_str << page.title
    link_str << link_to(page.title, wiki_path(page.title)) while page = page.parent
    link_str.reverse.join(' > ')
  end

  def render_page_content(page, rev=nil)
    case page.format_type
    when "hiki" then content_tag("div", render_hiki(page.content(rev)), :class => "rich_style")
    when "html" then render_richtext(page.content(rev))
    end
  end
end
