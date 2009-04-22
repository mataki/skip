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
module Admin::AdminModule
  module AdminUtil
    include ActionController::RecordIdentifier
    private

    # "Admin::User"
    def admin_model_class_name
      "Admin::"+controller_name.classify
    end

    # Admin::User
    def admin_model_class
      admin_model_class_name.constantize
    end

    # "admin_user"
    def admin_params_name
      singular_class_name(admin_model_class_name.constantize)
    end

    # :admin_user
    def admin_params_sym
      admin_params_name.to_sym
    end

    # admin_users_url
    def index_url
      eval(admin_params_name.pluralize+"_url")
    end

    # "user" "board entry"
    def singularize_name
      controller_name.singularize
    end

    # @user = object
    def set_singularize_instance_val(object)
      instance_variable_set '@'+singularize_name, object
    end

    # @users = objects
    def set_pluralize_instance_val(objects)
      instance_variable_set '@'+controller_name, objects
    end

    def object_name_without_admin(object)
      object.class.name[/[^Admin::](.*)$/].tableize.singularize
    end

    def search_condition
      columns = admin_model_class.search_columns
      columns.map{ |column| " #{column} like :lqs" }.join(' or ')
    end
  end

  module AdminRootModule
    include Admin::AdminModule::AdminUtil

    def index
      @query = params[:query]
      @pages, objects = paginate(singularize_name.to_sym,
                                 :per_page => 100,
                                 :class_name => admin_model_class_name,
                                 :conditions => [search_condition, { :lqs => SkipUtil.to_lqs(@query) }])
      set_pluralize_instance_val objects

      @topics = [_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}]

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => objects }
      end
    end

    def show
      object = admin_model_class.find(params[:id])
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, index_url],
                 _('%{model} Show') % {:model => object.topic_title}]

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => object }
      end
    end

    def new
      # @board_entry = Admin::BoardEntry.new
      object = admin_model_class.new
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, index_url],
                 _('New %{model}') % {:model => _(singularize_name.gsub('_', ' '))}]

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => object }
      end
    end

    def edit
      object = admin_model_class.find(params[:id])
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, index_url],
                 _('Editing %{model}') % {:model => object.topic_title}]
    end

    def create
      object = admin_model_class.new(params[admin_params_sym])
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, index_url],
                 _('New %{model}') % {:model => _(singularize_name.gsub('_', ' '))}]

      respond_to do |format|
        if object.save
          flash[:notice] = _("%{model} was successfully created.") % {:model => _(singularize_name.gsub('_', ' '))}
          format.html { redirect_to(object) }
          format.xml  { render :xml => object, :status => :created, :location => object }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
        end
      end
    end

    def update
      object = admin_model_class.find(params[:id])
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, index_url],
                 _('Editing %{model}') % {:model => object.topic_title}]

      respond_to do |format|
        if object.update_attributes(params[admin_params_sym])
          flash[:notice] = _("%{model} was successfully updated.") % {:model => _(singularize_name.gsub('_', ' '))}
          format.html { redirect_to(object) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
        end
      end
    end

    def destroy
      object = admin_model_class.find(params[:id])
      object.destroy
      set_singularize_instance_val object

      respond_to do |format|
        flash[:notice] = _("%{model} was successfully deleted.") % {:model => _(singularize_name.gsub('_', ' '))}
        format.html { redirect_to(index_url) }
        format.xml  { head :ok }
      end
    end

  end

  module AdminChildModule
    include Admin::AdminModule::AdminUtil

    def index
      objects = chiled_objects
      set_pluralize_instance_val objects

      @topics = [[_('Listing %{model}') % {:model => _(object_name_without_admin(load_parent).gsub('_', ' '))}, parent_index_path],
                 [_('%{model} Show') % {:model => load_parent.topic_title}, load_parent],
                 _('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}]

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => objects }
      end
    end

    def show
      object = chiled_objects.find(params[:id])
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(object_name_without_admin(load_parent).gsub('_', ' '))}, parent_index_path],
                 [_('%{model} Show') % {:model => load_parent.topic_title}, load_parent],
                 [_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, { :action => :index }],
                 _('%{model} Show') % {:model => object.topic_title}]

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => object }
      end
    end

    def new
      object = chiled_objects.build
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(object_name_without_admin(load_parent).gsub('_', ' '))}, parent_index_path],
                 [_('%{model} Show') % {:model => load_parent.topic_title}, load_parent],
                 [_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, { :action => :index }],
                 _('New %{model}') % {:model => object.topic_title}]

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => object }
      end
    end

    def edit
      object = chiled_objects.find(params[:id])
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(object_name_without_admin(load_parent).gsub('_', ' '))}, parent_index_path],
                 [_('%{model} Show') % {:model => load_parent.topic_title}, load_parent],
                 [_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, { :action => :index }],
                 _('Editing %{model}') % {:model => object.topic_title}]
    end

    def create
      object = chiled_objects.build(params[admin_params_sym])
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(object_name_without_admin(load_parent).gsub('_', ' '))}, parent_index_path],
                 [_('%{model} Show') % {:model => load_parent.topic_title}, load_parent],
                 [_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, { :action => :index }],
                 _('New %{model}') % {:model => object.topic_title}]

      respond_to do |format|
        if object.save
          flash[:notice] = _("%{model} was successfully created.") % {:model => _(singularize_name.gsub('_', ' '))}
          format.html { redirect_to(url_for_parent_and(object)) }
          format.xml  { render :xml => object, :status => :created, :location => object }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
        end
      end

    end

    def update
      object = chiled_objects.find(params[:id])
      set_singularize_instance_val object

      @topics = [[_('Listing %{model}') % {:model => _(object_name_without_admin(load_parent).gsub('_', ' '))}, parent_index_path],
                 [_('%{model} Show') % {:model => load_parent.topic_title}, load_parent],
                 [_('Listing %{model}') % {:model => _(singularize_name.gsub('_', ' '))}, { :action => :index }],
                 _('Editing %{model}') % {:model => object.topic_title}]

      respond_to do |format|
        if object.update_attributes(params[singularize_name.to_sym])
          flash[:notice] = _('%{model} was successfully updated.') % {:model => _(singularize_name.gsub('_', ' '))}
          format.html { redirect_to(url_for_parent_and(object)) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => object.errors, :status => :unprocessable_entity }
        end
      end
    end

    def destroy
      object = chiled_objects.find(params[:id])
      object.destroy
      set_singularize_instance_val object

      respond_to do |format|
        flash[:notice] = _("%{model} was successfully deleted.") % {:model => _(singularize_name.gsub('_', ' '))}
        format.html { redirect_to(url_for_parent) }
        format.xml  { head :ok }
      end
    end

    private
    def chiled_objects
      load_parent.send(controller_name.to_sym)
    end

    def url_for_parent_and(object)
      redirect_url = url_prefix+singularize_name+"_url"
      send(redirect_url.to_sym, load_parent, object)
    end

    def url_for_parent
      redirect_url = url_prefix+controller_name+"_url"
      send(redirect_url.to_sym, load_parent)
    end

    def parent_index_path
      eval("admin_"+object_name_without_admin(load_parent).pluralize+"_path")
    end
  end
end
