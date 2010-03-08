class AppliedEmailsController < ApplicationController
  def new
    @applied_email = AppliedEmail.find_or_initialize_by_user_id(current_user.id)
  end

  def create
    @user = current_user
    @applied_email = AppliedEmail.find_or_initialize_by_user_id(current_user.id)
    @applied_email.email = params[:applied_email][:email]

    if @applied_email.save
      UserMailer::Smtp.deliver_sent_apply_email_confirm(@applied_email.email, complete_tenant_user_applied_email_url(current_tenant, current_user, :id => @applied_email.onetime_code))
      flash[:notice] = _("Your request of changing email address accepted. Check your email to complete the process.")
      redirect_to new_tenant_user_applied_email_path(current_tenant, current_user)
    else
      render :new
    end
  end
  alias :update :create

  def complete
    if @applied_email = AppliedEmail.find_by_user_id_and_onetime_code(current_user.id, params[:id])
      @user = current_user
      old_email = @user.email
      @user.email = @applied_email.email
      if @user.save
        @applied_email.destroy
        flash[:notice] = _("Email address was updated successfully.")
      else
        flash[:notice] = _("The specified email address has already been registered. Try resubmitting the request with another address.")
      end
      redirect_to new_tenant_user_applied_email_path(current_tenant, current_user)
    else
      flash[:notice] = _('Specified page not found.')
      redirect_to root_url
    end
  end

end
