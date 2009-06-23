# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2009 TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Admin::UsersController < Admin::ApplicationController
  include Admin::AdminModule::AdminRootModule

  verify :method => :post, :only => ['lock_actives']

  skip_before_filter :sso, :only => [:first]
  skip_before_filter :login_required, :only => [:first]
  skip_before_filter :prepare_session, :only => [:first]
  skip_before_filter :require_admin, :only => [:first]

  def new
    @user = Admin::User.new
    @user_uid = Admin::UserUid.new
    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path], _('New %{model}') % {:model => _('user')}]
  end

  def create
    begin
      Admin::User.transaction do
        @user, @user_uid = Admin::User.make_new_user({:user => params[:user], :user_uid => params[:user_uid]})
        @user.save!
      end
      flash[:notice] = _('Registered.')
      redirect_to admin_users_path
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path], _('New %{model}') % {:model => _('user')}]
      render :action => 'new'
    end
  end

  def edit
    @user = Admin::User.find(params[:id])
    @user_uid = @user.master_user_uid

    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path],
               _('Editing %{model}') % {:model => @user.topic_title }]
  rescue ActiveRecord::RecordNotFound => e
    flash[:notice] = _('User does not exist.')
    redirect_to admin_users_path
  end

  def update
    @user = Admin::User.make_user_by_id(params)
    if @user.id == current_user.id and (@user.status != current_user.status or @user.admin != current_user.admin or @user.locked != current_user.locked)
      @user.status = current_user.status
      @user.admin = current_user.admin
<<<<<<< HEAD:app/controllers/admin/users_controller.rb
      @user.locked = current_user.locked
      @user.errors.add_to_base(_('You cannot update status and admin and lock of yourself'))
=======
      @user.errors.add_to_base(_('Admins are not allowed to change their own status and admin rights. Log in with another admin account to do so.'))
>>>>>>> for_i18n:app/controllers/admin/users_controller.rb
      raise ActiveRecord::RecordInvalid.new(@user)
    end
    @user.trial_num = 0 unless @user.locked
    @user.save!
    flash[:notice] = _('Updated.')
    redirect_to :action => "edit"
  rescue ActiveRecord::RecordNotFound => e
    flash[:notice] = _('User does not exist.')
    redirect_to admin_users_path
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path],
               _('Editing %{model}') % {:model => @user.topic_title }]
    render :action => 'edit'
  end

  def destroy
    @user = Admin::User.find(params[:id])
    if @user.unused?
      @user.destroy
      flash[:notice] = _('User was successfuly deleted.')
    else
      flash[:notice] = _("You cannot delete user who is not unused.")
    end
    redirect_to admin_users_path
  end

  def first
    if valid_activation_code? params[:code]
      if request.get?
        @user = Admin::User.new
        @user_uid = Admin::UserUid.new
        render :layout => 'not_logged_in'
      else
        begin
          Admin::User.transaction do
            @user, @user_uid = Admin::User.make_user({:user => params[:user], :user_uid => params[:user_uid]}, true)
            @user.user_access = UserAccess.new :last_access => Time.now, :access_count => 0
            @user.save!
            if activation = Activation.find_by_code(params[:code])
              activation.update_attributes(:code => nil)
            end
          end
          flash[:notice] = _('Registered.') + _('Log in again.')
          redirect_to :controller => "/platform", :action => :index
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
          render :layout => 'not_logged_in'
        end
      end
    else
<<<<<<< HEAD:app/controllers/admin/users_controller.rb
      contact_link = "<a href=\"mailto:#{SkipEmbedded::InitialSettings['administrator_addr']}\" target=\"_blank\">お問い合わせ</a>"
=======
      contact_link = "<a href=\"mailto:#{INITIAL_SETTINGS['administrator_addr']}\" target=\"_blank\">" + _('Inquiries') + '</a>'
>>>>>>> for_i18n:app/controllers/admin/users_controller.rb
      if User.find_by_admin(true)
        flash[:error] = _('Administrative user has already been registered. Log in with the account or contact {contact_link} in case of failure.') % {:contact_link => contact_link}
        redirect_to :controller => "/platform", :action => :index
      else
        flash.now[:error] = _('Operation unauthorized. Verify the URL and retry. Contact %{contact_link} if the problem persists.') % {:contact_link => contact_link}
        render :text => '', :status => :forbidden, :layout => 'not_logged_in'
      end
    end
  end

  def import_confirmation
    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path], _('New users from CSV')]
    if request.get? || !valid_file?(params[:file], :content_types => ['text/csv', 'application/x-csv', 'application/vnd.ms-excel'])
      @users = []
      return render(:action => :import)
    end
    @users = Admin::User.make_users(params[:file], params[:options], params[:update_registered].blank?)
    import!(@users)
    flash.now[:notice] = _('Verified content of CSV file.')
    render :action => :import
  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotSaved => e
<<<<<<< HEAD:app/controllers/admin/users_controller.rb
    @users.each {|user, user_uid| user.valid?}
    flash.now[:notice] = _('CSVファイルの内容を検証しました。')
=======
    @users.each {|user, user_profile, user_uid| user.valid?}
    flash.now[:notice] = _('Verified content of CSV file.')
>>>>>>> for_i18n:app/controllers/admin/users_controller.rb
    render :action => :import
  end

  def import
    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path], _('New users from CSV')]
    @error_row_only = true
    if request.get? || !valid_file?(params[:file], :content_types => ['text/csv', 'application/x-csv', 'application/vnd.ms-excel'])
      @users = []
      return
    end
    @users = Admin::User.make_users(params[:file], params[:options], params[:update_registered].blank?)
    import!(@users, false)
    flash[:notice] = _('Successfully added/updated users from CSV file.')
    redirect_to admin_users_path
  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotSaved => e
<<<<<<< HEAD:app/controllers/admin/users_controller.rb
    @users.each {|user, user_uid| user.valid?}
    flash.now[:error] = _('CSVファイルに不正な値が含まれています。')
=======
    @users.each {|user, user_profile, user_uid| user.valid?}
    flash.now[:error] = _('Illegal value(s) found in CSV file.')
>>>>>>> for_i18n:app/controllers/admin/users_controller.rb
  end

  def change_uid
    @user = Admin::User.find(params[:id])
    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path],
               [_('Editing %{model}') % {:model => @user.topic_title}, edit_admin_user_path(@user)],
               _('Change uid')]

    if request.get? or not @user.active?
      @user_uid = Admin::UserUid.new
      return
    end

    if uid = @user.user_uids.find(:first, :conditions => ['uid_type = ?', UserUid::UID_TYPE[:username]])
      uid.uid = params[:user_uid] ? params[:user_uid][:uid] : ''
      if uid.save
        flash[:notice] = _("Update complete.")
        redirect_to :action => "edit"
      else
        @user_uid = uid
      end
    else
      flash[:notice] = _("User name not found.")
      redirect_to admin_users_path
    end
  end

  def create_uid
    @user = Admin::User.find(params[:id])
    @topics = [[_('Listing %{model}') % {:model => _('user')}, admin_users_path],
               [_('Editing %{model}') % {:model => @user.topic_title}, edit_admin_user_path(@user)],
               _('Create %{name}') % { :name => _('user name')}]

    if request.get? or not @user.active?
      @user_uid = Admin::UserUid.new
      return
    end

    if @user.user_uids.find(:first, :conditions => ['uid_type = ?', UserUid::UID_TYPE[:username]])
      flash[:error] = _("User %{username} has already been registered.") % {:username => _('user name')}
      redirect_to(@user)
      return
    end

    @user_uid = @user.user_uids.build(params[:user_uid].merge!(:uid_type => UserUid::UID_TYPE[:username]))
    if @user_uid.save
      flash[:notice] = _('User was successfully registered.')
      redirect_to :action => "edit"
    end
  end

  def show_signup_url
    @user = Admin::User.find(params[:id])
    @signup_url = signup_url(@user.activation_token)
    @mail_body = render_to_string(:template => "user_mailer/sent_activate", :layout => false)
    render :layout => false
  end

  def issue_activation_code
    user = Admin::User.find(params[:id])
    if user.unused?
      user.issue_activation_code
      user.save_without_validation!
      email = user.email
      UserMailer.deliver_sent_activate(email, signup_url(user.activation_token))
      flash[:notice] = Admin::Setting.mail_function_setting ?  _("ユーザ登録のためのURLを記載したメールを%{email}宛てに送信しました。") % {:email => email} : _('利用開始URLを発行しました。確認のリンクからユーザに連絡してください。')
    else
      flash[:error] = _("メールアドレスが%{email}のユーザは既に利用を開始しています。") % {:email => email}
    end
    redirect_to admin_users_path
  end

  def issue_password_reset_code
    @user = Admin::User.find(params[:id])
    if @user.active?
      if @user.reset_auth_token.nil? || !@user.within_time_limit_of_reset_auth_token?
        @user.issue_reset_auth_token
        @user.save_without_validation!
      end
      @reset_password_url = reset_password_url(@user.reset_auth_token)
      @mail_body = render_to_string(:template => "user_mailer/sent_forgot_password", :layout => false)
      render :layout => false
    else
      flash[:error] = _('未使用ユーザのパスワード再設定コードは発行できません。')
      redirect_to edit_admin_user_path(params[:id])
    end
  end

  def lock_actives
    flash[:notice] = _('%{count}件更新しました。')%{:count => Admin::User.lock_actives}
    redirect_to admin_settings_path(:tab => :security)
  end

  private
  def valid_activation_code? code
    return false unless code
    return true if Activation.find_by_code(code)
    false
  end

  def import!(users, rollback = true)
    Admin::User.transaction do
      users.each do |user, user_uid|
        user.save!
        unless user.new_record?
          user_uid.save!
        end
      end
      raise ActiveRecord::Rollback if rollback
    end
  end
end
