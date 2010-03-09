class MessageUnsubscribesController < ApplicationController
  def edit
    @user = current_user
    @unsubscribes = current_user.user_message_unsubscribes.map(&:message_type)
  end

  def update
    current_user.user_message_unsubscribes.delete_all
    SystemMessage::MESSAGE_TYPES.each do |message_type|
      unless  params["message_type"] && params["message_type"][message_type]
        current_user.user_message_unsubscribes.create :message_type => message_type
      end
    end
    flash[:notice] = _('Updated notification email settings.')
    redirect_to edit_tenant_user_message_unsubscribe_url(current_tenant, current_user)
  end
end
