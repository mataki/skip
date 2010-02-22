class InvitationsController < ApplicationController
  def new
    @invitation = current_user.invitations.build
    @invitation.subject = _('You are invited to the %{abbr_app_title} from %{user_name}') % {:abbr_app_title => Admin::Setting.abbr_app_title, :user_name => current_user.name}
    @invitation.body = File.read("#{RAILS_ROOT}/public/custom/default_invitation_body.txt")
    respond_to do |format|
      format.html
    end
  end

  def create
    @invitation = current_user.invitations.build(params[:invitation])
    respond_to do |format|
      if @invitation.save
        UserMailer::Smtp.deliver_sent_invitation(@invitation)
        flash[:notice] = _('Succeeded to invite.')
        format.html { redirect_to root_url }
      else
        format.html { render :action => 'new' }
      end
    end
  end
end
