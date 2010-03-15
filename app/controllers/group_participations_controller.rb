class GroupParticipationsController < ApplicationController
  before_filter :target_group_required
  before_filter :required_full_accessible_group_participation, :except => %w(create)

  def create
    group = current_target_group
    group_participation = group.group_participations.build
    group_participation.user = current_user

    required_full_accessible_group_participation(group_participation) do
      group_participation.join!(current_user) do |result, participation|
        if result
          if participation.waiting?
            flash[:notice] = _('Request sent. Please wait for the approval.')
          else
            group.group_participations.only_owned.each do |owner_participation|
              SystemMessage.create_message :message_type => 'JOIN', :user_id => owner_participation.user_id, :message_hash => {:group_id => group.id}
            end
            flash[:notice] = _('Joined the group successfully.')
          end
        else
          flash[:error] = group.errors.full_messages
        end
      end
      redirect_to [current_tenant, group]
    end
  end

  def destroy
    group = current_target_group
    current_target_group_participation.leave(current_user)
    group.group_participations.only_owned.each do |owner_participation|
      SystemMessage.create_message :message_type => 'LEAVE', :user_id => owner_participation.user_id, :message_hash => {:user_id => current_user.id, :group_id => group.id}
    end
    flash[:notice] = _('Successfully left the group.')
    redirect_to [current_tenant, group]
  end

  private
  def current_target_group_participation
    @current_target_group_participation ||= current_target_group.group_participations.find params[:id]
  end

  def required_full_accessible_group_participation group_participation = current_target_group_participation
    if result = group_participation.full_accessible?(current_user)
      yield if block_given?
    else
      respond_to do |format|
        format.html { redirect_to_with_deny_auth }
        format.js { render :text => _('Operation unauthorized.'), :status => :forbidden }
      end
    end
    result
  end
end
