module WikiHelper
  def wiki_tab_menu_source page
    tab_menu_source = []
    tab_menu_source << {:label => _('Contents'), :options => wiki_path(page.title)}
    tab_menu_source << {:label => _('History'), :options => {:controller => 'wikis', :action => 'show', :id=>page.title}}
    tab_menu_source << {:label => _('Search'), :options => {:controller => 'wikis', :action => 'show', :id=>page.title}}
    tab_menu_source
  end
end
