module AccessibleGroup
  def required_full_accessible_group group = current_target_group
    if result = current_target_group && current_target_group.owned?(current_user)
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
