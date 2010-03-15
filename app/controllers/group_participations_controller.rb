class GroupParticipationsController < ApplicationController
  include AccessibleGroup
  before_filter :target_group_required
  before_filter :required_full_accessible_group, :only => %w(manage_members add_admin_control remove_admin_control approve disapprove)
  before_filter :required_full_accessible_group_participation, :only => %w(destroy)

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
    current_target_group_participation.leave
    respond_to do |format|
      format.html do
        if current_user == current_target_group_participation.user
          group.group_participations.only_owned.each do |owner_participation|
            SystemMessage.create_message :message_type => 'LEAVE', :user_id => owner_participation.user_id, :message_hash => {:user_id => current_user.id, :group_id => group.id}
          end
          flash[:notice] = _('Successfully left the group.')
          redirect_to [current_tenant, group]
        else
          SystemMessage.create_message :message_type => 'FORCED_LEAVE', :user_id => current_target_group_participation.user.id, :message_hash => {:group_id => group.id}
          flash[:notice] = _("Removed %s from members of the group.") % current_target_group_participation.user.name
          redirect_to polymorphic_url([current_tenant, group, :group_participation], :action => :manage_members)
        end
      end
    end
  end

  def manage_members
    @participations = current_target_group.group_participations.active.paginate(:page => params[:page], :per_page => 20)
  end

  def add_admin_control
    current_target_group_participation.owned = true
    current_target_group_participation.save
    respond_to do |format|
      format.html { redirect_to polymorphic_path([current_tenant, current_target_group, :group_participation], :action => :manage_members) }
    end
  end

  def remove_admin_control
    current_target_group_participation.owned = false
    current_target_group_participation.save
    respond_to do |format|
      format.html { redirect_to polymorphic_path([current_tenant, current_target_group, :group_participation], :action => :manage_members) }
    end
  end

  def manage_waiting_members
    @participations = current_target_group.group_participations.waiting.paginate(:page => params[:page], :per_page => 20)
  end

  def approve
    group = current_target_group
    current_target_group_participation.waiting = false
    current_target_group_participation.save
    unless current_target_group_participation.user.notices.find_by_target_id(group.id)
      current_target_group_participation.user.notices.create!(:target => group)
    end
    SystemMessage.create_message :message_type => 'APPROVAL_OF_JOIN', :user_id => current_target_group_participation.user.id, :message_hash => {:group_id => group.id}
    respond_to do |format|
      format.html do
        flash[:notice] = _("Succeeded to Approve.")
        redirect_to polymorphic_path([current_tenant, current_target_group, :group_participation], :action => :manage_waiting_members)
      end
    end
  end

  def disapprove
    group = current_target_group
    current_target_group_participation.destroy
    SystemMessage.create_message :message_type => 'DISAPPROVAL_OF_JOIN', :user_id => current_target_group_participation.user.id, :message_hash => {:group_id => group.id}
    respond_to do |format|
      format.html do
        flash[:notice] = _("Succeeded to Disapprove.")
        redirect_to polymorphic_path([current_tenant, current_target_group, :group_participation], :action => :manage_waiting_members)
      end
    end
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
