ActionController::Routing::Routes.draw do |map|

  map.root    :controller => 'mypage', :action => 'index'

  map.resources :pictures

  map.resources :notices

  map.share_file  ':controller_name/:symbol_id/files/:file_name',
                  :controller => 'share_file',
                  :action => 'download',
                  :requirements => {  :file_name => /.*/, :symbol_id => /[a-zA-Z0-9\-_\.]+/ }

  map.with_options :controller => "ids" do |ids|
    ids.identity "id/:user", :action => 'show', :user => /[a-zA-Z0-9\-_\.]*/
    ids.formatted_identity "id/:user/:format", :action => "show", :user => /[a-zA-Z0-9\-_\.]*/
  end

  map.with_options(:requirements => { :uid => /[a-zA-Z0-9\-_\.]+/ }) do |user_req|
    user_req.user_bookmark 'user/:uid/bookmark', :controller => 'bookmark', :action => 'list'
    user_req.user_share_file 'user/:uid/share_file', :controller => 'share_file', :action => 'list'
    user_req.with_options( :controller => 'user',:requirements => { :uid => /[a-zA-Z0-9\-_\.]+/ }, :defaults => { :action => 'show' }) do |user|
      user.connect 'user/:uid/:action'
      user.connect 'user/:uid/:action.:format'
    end
  end

  map.group_share_file 'group/:gid/share_file', :controller => 'share_file', :action => 'list'
  map.with_options( :controller => 'group', :defaults => { :action => 'show' } ) do |group|
    group.connect 'group/:gid/:action'
    group.connect 'group/:gid/:action.:format'
  end

  map.connect 'bookmark/:action/:uri',
              :controller => 'bookmark',
              :defaults => { :action => 'show' },
              :uri => /.*/

  map.connect 'page/:id',
              :controller => 'board_entries',
              :action => 'forward'

  map.with_options(:controller => "platform") do |platform|
    platform.login "platform", :action => "index"
    platform.perform_login 'login', :action => 'login'
    platform.logout 'logout', :action => 'logout'
    platform.forgot_password 'platform/forgot_password', :action => 'forgot_password'
    platform.reset_password 'platform/reset_password/:code', :action => 'reset_password'
    platform.activate 'platform/activate', :action => 'activate'
    platform.signup 'platform/signup/:code', :action => 'signup'
    platform.forgot_openid 'platform/forgot_openid', :action => 'forgot_openid'
    platform.reset_openid 'platform/reset_openid/:code', :action => 'reset_openid'
  end

  map.monthly 'rankings/monthly/:year/:month',
              :controller => 'rankings',
              :action => 'monthly',
              :year => /\d{4}/,
              :month => /\d{1,2}/,
              :conditions => { :method => :get },
              :defaults => { :year => '', :month => '' }

  map.ranking_data 'ranking_data/:content_type/:year/:month',
              :controller => 'rankings',
              :action => 'data',
              :year => /\d{4}/,
              :month => /\d{1,2}/,
              :conditions => { :method => :get },
              :defaults => { :year => '', :month => '' }

  map.namespace "admin" do |admin_map|
    admin_map.root :controller => 'settings', :action => 'index', :tab => 'main'
    admin_map.resources :board_entries, :only => [:index, :show, :destroy] do |board_entry|
      board_entry.resources :board_entry_comments, :only => [:index, :destroy]
    end
    admin_map.resources :share_files, :only => [:index, :destroy], :member => [:download]
    admin_map.resources :bookmarks, :only => [:index, :show, :destroy] do |bookmark|
      bookmark.resources :bookmark_comments, :only => [:index, :destroy]
    end
    admin_map.resources :users, :new => [:import, :import_confirmation, :first], :member => [:change_uid, :create_uid, :show_signup_url, :issue_activation_code, :issue_password_reset_code], :collection => [:lock_actives, :issue_activation_codes] do |user|
      user.resources :openid_identifiers, :only => [:edit, :update, :destroy]
      user.resource :user_profile
      user.resource :picture
    end
    admin_map.resources :pictures
    admin_map.resources :groups, :only => [:index, :show, :destroy] do |group|
      group.resources :group_participations, :only => [:index, :destroy]
    end
    admin_map.resources :group_categories
    admin_map.resources :user_profile_master_categories
    admin_map.resources :user_profile_masters
    admin_map.settings_update_all 'settings/:tab/update_all', :controller => 'settings', :action => 'update_all'
    admin_map.settings_ado_feed_item 'settings/ado_feed_item', :controller => 'settings', :action => 'ado_feed_item'
    admin_map.settings 'settings/:tab', :controller => 'settings', :action => 'index', :defaults => { :tab => '' }

    admin_map.documents 'documents/:target', :controller => 'documents', :action => 'index', :defaults => { :target => '' }
    admin_map.documents_update 'documents/:target/update', :controller => 'documents', :action => 'update'
    admin_map.documents_revert 'documents/:target/revert', :controller => 'documents', :action => 'revert'

    admin_map.images 'images', :controller => 'images', :action => 'index'
    admin_map.images_update 'images/:target/update', :controller => 'images', :action => 'update'
    admin_map.images_revert 'images/:target/revert', :controller => 'images', :action => 'revert'

    admin_map.resources :oauth_providers, :member => {:toggle_status => :post}
  end

  map.with_options :controller => 'server' do |server|
    server.formatted_server 'server.:format', :action => 'index'
    server.server 'server', :action => 'index'
    server.proceed 'server/proceed', :action => 'proceed'
    server.cancel 'server/cancel', :action => 'cancel'
  end

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.web_parts 'services/:action.js', :controller => 'services'

end
