module WikiHelper
  def wiki_tab_menu_source page
    tab_menu_source = []
    tab_menu_source << {:label => _('Contents'), :options => {:controller => 'wiki', :action => 'show', :id=>page.title}}
    tab_menu_source << {:label => _('History'), :options => {:controller => 'wiki', :action => 'show', :id=>page.title}}
    tab_menu_source << {:label => _('Search'), :options => {:controller => 'wiki', :action => 'show', :id=>page.title}}
    tab_menu_source
  end
end
