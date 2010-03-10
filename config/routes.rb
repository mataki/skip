ActionController::Routing::Routes.draw do |map|
  map.resources :tenants, :only => [] do |tenant|
    tenant.root :controller => :mypages, :action => :index
    tenant.resource :mypage, :only => [], :collection => {:welcome => :get}
    tenant.resource :platform, :only => %(show),
      :member => {
        :login => :post,
        :logout => :any,
        :activate => :any,
        :forgot_password => :any,
        :reset_password => :any,
        :signup => :any
      }
    tenant.resources :users, :new => {:agreement => :get}, :member => {:update_active => :put} do |user|
      user.resources :board_entries, :member => {:print => :get, :toggle_hide => :put}, :collection => {:preview => :post} do |board_entry|
        board_entry.resources :entry_trackbacks, :only => %w(destroy)
        board_entry.resource :board_entry_point, :only => [], :member => {:pointup => :put}
        board_entry.resources :board_entry_comments, :only => %w(create edit update destroy)
        board_entry.resources :entry_hide_operations, :only => %w(index)
      end
      user.resources :share_files, :member => {:download_history_as_csv => :get, :clear_download_history => :delete}
      user.resources :pictures, :only => %w(show new create update destroy)
      user.resource :password, :only => %w(edit update)
      user.resource :applied_email, :only => %w(new create update), :member => {:complete => :get}
      user.resource :id, :only => %w(show edit create update)
      user.resource :message_unsubscribe, :only => %w(edit update)
      user.resource :customize, :only => %w(update)
      user.resources :chains, :collection => {:against => :get}
      user.resources :system_messages, :only => [:destroy]
      user.resources :notices
      # ユーザの参加グループ一覧のため
      user.resources :groups, :only => %w(index)
    end
    tenant.resources :groups, :member => {:manage => :get} do |group|
      group.resources :board_entries, :member => {:print => :get, :toggle_hide => :put}, :collection => {:preview => :post} do |board_entry|
        board_entry.resources :entry_trackbacks, :only => %w(destroy)
        board_entry.resource :board_entry_point, :only => [], :member => {:pointup => :put}
        board_entry.resources :board_entry_comments, :only => %w(create edit update destroy)
        board_entry.resources :entry_hide_operations, :only => %w(index)
      end
      group.resources :share_files, :member => {:download_history_as_csv => :get, :clear_download_history => :delete}
    end
    tenant.resources :share_files, :only => %w(index show)
    tenant.resources :board_entries, :only => %w(index show)
  end

  map.namespace "admin" do |admin_map|
    admin_map.resources :tenants, :only => [] do |tenant|
      tenant.root :controller => 'settings', :action => 'index', :tab => 'main'
      tenant.resources :board_entries, :only => [:index, :show, :destroy], :member => {:close => :put} do |board_entry|
        board_entry.resources :board_entry_comments, :only => [:index, :destroy]
      end
      tenant.resources :share_files, :only => [:index, :destroy], :member => [:download]
  #      tenant.resources :bookmarks, :only => [:index, :show, :destroy] do |bookmark|
  #        bookmark.resources :bookmark_comments, :only => [:index, :destroy]
  #      end
      tenant.resources :users, :new => [:import, :import_confirmation, :first], :member => [:change_uid, :create_uid, :issue_activation_code, :issue_password_reset_code], :collection => [:lock_actives, :reset_all_password_expiration_periods, :issue_activation_codes] do |user|
  #        user.resources :openid_identifiers, :only => [:edit, :update, :destroy]
        user.resource :user_profile
        user.resource :pictures, :only => %w(new create)
      end
      tenant.resources :pictures, :only => %w(index show destroy)
      tenant.resources :groups, :only => [:index, :show, :destroy] do |group|
        group.resources :group_participations, :only => [:index, :destroy]
      end
      tenant.resources :masters, :only => [:index]
      tenant.resources :group_categories
      tenant.resources :user_profile_master_categories
      tenant.resources :user_profile_masters
      tenant.settings_update_all 'settings/:tab/update_all', :controller => 'settings', :action => 'update_all'
      tenant.settings_ado_feed_item 'settings/ado_feed_item', :controller => 'settings', :action => 'ado_feed_item'
      tenant.settings 'settings/:tab', :controller => 'settings', :action => 'index', :defaults => { :tab => '' }

      tenant.documents 'documents/:target', :controller => 'documents', :action => 'index', :defaults => { :target => '' }
      tenant.documents_update 'documents/:target/update', :controller => 'documents', :action => 'update'
      tenant.documents_revert 'documents/:target/revert', :controller => 'documents', :action => 'revert'

      tenant.images 'images', :controller => 'images', :action => 'index'
      tenant.images_update 'images/:target/update', :controller => 'images', :action => 'update'
      tenant.images_revert 'images/:target/revert', :controller => 'images', :action => 'revert'
    end
  end

  map.namespace "apps" do |app|
    app.resources :events, :member => {:attend => :post, :absent => :post}, :collection => { :recent => :get }, :except => [:destroy] do |event|
      event.resources :attendees, :only => [:update]
    end
    app.resource :javascripts, :only => [], :member => {:application => :get}
  end

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
