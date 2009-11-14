module WikiHelper
  def wiki_tab_menu_source page
    tab_menu_source = []
    tab_menu_source << {:label => _('Contents'), :options => wiki_path(page.title)}
    tab_menu_source
  end

  def generate_wiki_topics_str page
    link_str = []
    # First Page
    link_str << page.title
    link_str << link_to(page.title, wiki_path(page.title)) while page = page.parent
    link_str.reverse.join(' > ')
  end
end
