# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

# FIXME new, edit, updateに本人かどうかのチェックがいる
# FIXME new, update, agreementにrequired_loginに相当するチェックがいる
class UsersController < ApplicationController
  skip_before_filter :prepare_session, :only => %w(agreement new update_active)
  skip_before_filter :sso, :only => %w(agreement new update_active)
  skip_before_filter :login_required, :only => %w(agreement new update_active)
  before_filter :target_user_required, :only => %w(show edit update)
  before_filter :registerable_filter, :only => %w(agreement new update_active)
  after_filter :mark_track, :only => %w(show)
  after_filter :remove_system_message, :only => %w(show)

  # tab_menu
  def index
    @search = User.tagged(params[:tag_words], params[:tag_select]).profile_like(params[:profile_master_id], params[:profile_value]).descend_by_user_access_last_access.search(params[:search])
    @search.exclude_retired ||= '1'
    user_ids = @search.paginate_without_retired_skip(:all, {:include => %w(user_access), :page => params[:page]}).map(&:id)
    # 上記のみでは検索条件や表示順の条件によって、user_uidsがMASTERかNICKNAMEのどちらかしたロードされない。
    # そのためviewで正しく描画するためにidのみ条件にして取得し直す
    @users = User.id_is(user_ids).descend_by_user_access_last_access.paginate_without_retired_skip(:all, {:include => %w(user_access picture), :page => params[:page]})

    flash.now[:notice] = _('User not found.') if @users.empty?
    @tags = ChainTag.popular_tag_names
    params[:tag_select] ||= "AND"
    @main_menu = @title = _('Users')
  end

  def show
    # 紹介してくれた人一覧
    @against_chains = current_target_user.against_chains.order_new.limit(5)
  end

  def new
    unless current_user
      flash[:error] = _('Unable to continue with the user registration process. A fresh start is required.')
      redirect_to platform_url
      return
    end
    @user = current_user
    @profiles = current_user.user_profile_values
    respond_to do |format|
      format.html
    end
  end

  def edit
    @title = _("Self Admin")
    @user = current_user
    @profiles = current_user.user_profile_values
  end

  # プロフィール更新
  def update
    @user = current_user
    @user.attributes = params[:user]
    @profiles = @user.find_or_initialize_profiles(params[:profile_value])

    User.transaction do
      @user.save!
      @profiles.each{|profile| profile.save!}
    end
    flash[:notice] = _('User information was successfully updated.')
    redirect_to [current_tenant, @user]
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    @error_msg = []
    @error_msg.concat @user.errors.full_messages unless @user.valid?
    @error_msg.concat SkipUtil.full_error_messages(@profiles)

    render :action => :edit
  end

  # 利用開始登録
  def update_active
    @user = current_user
      @user.attributes = params[:user]
      if @user.within_time_limit_of_activation_token?
        @user.crypted_password = nil
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
      end

      @profiles = @user.find_or_initialize_profiles(params[:profile_value])

      User.transaction do
        @profiles.each{|profile| profile.save!}
        @user.created_on = Time.now
        @user.status = 'ACTIVE'
        @user.save!

        UserAccess.create!(:user_id => @user.id, :last_access => Time.now, :access_count => 0)
        UserMailer::Smtp.deliver_sent_signup_confirm(@user.email, @user.code, root_url)

        @user.activate!

        session[:agreement] = nil
        redirect_to welcome_tenant_mypage_url(current_tenant)
      end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    @error_msg = []
    @error_msg.concat @user.errors.full_messages.reject{|msg| msg.include?("User uid") } unless @user.valid?
    @error_msg.concat SkipUtil.full_error_messages(@profiles)
    @user.status = 'UNUSED'

    render :action => :new
  end

  def agreement
    session[:agreement] = :agree
    redirect_to :action => :new
  end

  private
  def registerable_filter
    if current_user and !current_user.unused?
      redirect_to root_url
      return false
    end

    if Admin::Setting.stop_new_user
      @deny_message = _("New user registration is suspended for now.")
    end
    if @deny_message
      render :action => :deny_register
      return false
    end
  end

  def mark_track
    current_target_user.mark_track(current_user.id) if current_target_user.id != current_user.id
  end
end

