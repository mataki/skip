class PasswordsController < ApplicationController
  before_filter :password_mode_required

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.change_password(params[:user])
    if @user.errors.empty?
      flash[:notice] = _('Password was successfully updated.')
      redirect_to edit_tenant_user_password_url(current_tenant, current_user)
    else
      render :action => :edit
    end
  end

  private
  def password_mode_required
    unless login_mode?(:password)
      redirect_to_with_deny_auth edit_tenant_user_path(current_tenant, current_user)
    end
  end
end
