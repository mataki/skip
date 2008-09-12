ActionController::Routing::Routes.draw do |map|

  map.root    :controller => 'mypage', :action => 'index'

  map.connect 'images/*path',
              :controller => 'image',
              :action     => 'show'

  map.share_file  ':controller_name/:symbol_id/files/:file_name',
                  :controller => 'share_file',
                  :action => 'download',
                  :requirements => {  :file_name => /.*/ }

  map.connect 'user/:uid/:action',
              :controller => 'user',
              :defaults => { :action => 'show' }

  map.connect 'group/:gid/:action',
              :controller => 'group',
              :defaults => { :action => 'show' }

  map.connect 'bookmark/:action/:uri',
              :controller => 'bookmark',
              :defaults => { :action => 'show' },
              :uri => /.*/

  map.connect 'page/:id',
              :controller => 'board_entries',
              :action => 'forward'

  map.connect 'login', :controller => 'platform', :action => 'login'
  map.connect 'logout', :controller => 'platform', :action => 'logout'

  map.monthly 'rankings/monthly/:year/:month', :controller => 'rankings', :action => 'monthly', :year => /\d{4}/, :month => /\d{1,2}/, :conditions => { :method => :get }, :defaults => { :year => '', :month => '' }
  map.ranking_data 'ranking_data/:content_type/:year/:month', :controller => 'rankings', :action => 'data', :year => /\d{4}/, :month => /\d{2}/, :conditions => { :method => :get }, :defaults => { :year => '', :month => '' }

  map.namespace "admin" do |admin_map|
    admin_map.root :controller => 'settings', :action => 'index', :tab => 'main'
    admin_map.resources :board_entries do |board_entry|
      board_entry.resources :board_entry_comments
    end
    admin_map.resources :share_files
    admin_map.resources :bookmarks do |bookmark|
      bookmark.resources :bookmark_comments
    end
    admin_map.resources :users, :new => [:import, :import_confirmation, :first], :member => [:change_uid] do |user|
      user.resources :openid_identifiers
    end
    admin_map.resources :user_profiles
    admin_map.resources :groups do |group|
      group.resources :group_participations
    end
    admin_map.resources :group_categories
    admin_map.settings_update_all 'settings/:tab/update_all', :controller => 'settings', :action => 'update_all'
    admin_map.settings_ado_feed_item 'settings/ado_feed_item', :controller => 'settings', :action => 'ado_feed_item'
    admin_map.settings_ado_antenna_default_group 'settings/ado_antenna_default_group', :controller => 'settings', :action => 'ado_antenna_default_group'
    admin_map.settings 'settings/:tab', :controller => 'settings', :action => 'index', :defaults => { :tab => 'literal' }

    admin_map.documents_update 'documents/:target/update', :controller => 'documents', :action => 'update'
    admin_map.documents 'documents/:target', :controller => 'documents', :action => 'index', :defaults => { :target => '' }

    admin_map.images 'images', :controller => 'images', :action => 'index'
    admin_map.images_update 'images/:target/update', :controller => 'images', :action => 'update'
    admin_map.images_revert 'images/:target/revert', :controller => 'images', :action => 'revert'
  end

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.web_parts 'services/:action.js', :controller => 'services'

end
