module AdminModule
  module AdminUtil
    include ActionController::RecordIdentifier
    private

    # "Admin::Account"
    def admin_model_class_name
      "Admin::"+controller_name.classify
    end

    # Admin::Account
    def admin_model_class
      admin_model_class_name.constantize
    end

    # "admin_account"
    def admin_params_name
      singular_class_name(admin_model_class_name.constantize)
    end

    # :admin_account
    def admin_params_sym
      admin_params_name.to_sym
    end

    # admin_accounts_url
    def index_url
      eval(admin_params_name.pluralize+"_url")
    end

    # @account = object
    def set_singularize_instance_val(object)
      instance_variable_set '@'+controller_name.singularize, object
    end

    # @accounts = objects
    def set_pluralize_instance_val(objects)
      instance_variable_set '@'+controller_name, objects
    end
  end

  module AdminRootModule
    include AdminModule::AdminUtil

    def index
      @query = params[:query]
      objects = admin_model_class.find(:all, :conditions => [admin_model_class.search_colomns, { :lqs => SkipUtil.to_lqs(@query) }])
      set_pluralize_instance_val objects

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => objects }
      end
    end

    def show
      object = admin_model_class.find(params[:id])
      set_singularize_instance_val object

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => object }
      end
    end

    def new
      # @board_entry = Admin::BoardEntry.new
      object = admin_model_class.new
      set_singularize_instance_val object

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => object }
      end
    end

    def edit
      object = admin_model_class.find(params[:id])
      set_singularize_instance_val object
    end

    def create
      object = admin_model_class.new(params[admin_params_sym])
      set_singularize_instance_val object

      respond_to do |format|
        if object.save
          flash[:notice] = 'Admin::BoardEntry was successfully created.'
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

      respond_to do |format|
        if object.update_attributes(params[admin_params_sym])
          flash[:notice] = 'Admin::BoardEntry was successfully updated.'
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
        format.html { redirect_to(index_url) }
        format.xml  { head :ok }
      end
    end

  end

  module AdminChildModule
    include AdminModule::AdminUtil

    def index
      objects = chiled_objects
      set_pluralize_instance_val objects

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => objects }
      end
    end

    def show
      object = chiled_objects.find(params[:id])
      set_singularize_instance_val object

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => object }
      end
    end

    def new
      object = admin_model_class.new
      set_singularize_instance_val object

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => object }
      end
    end

    def edit
      object = chiled_objects.find(params[:id])
      set_singularize_instance_val object
    end

    def create
      object = chiled_objects.build(params[admin_params_sym])
      set_singularize_instance_val object

      respond_to do |format|
        if object.save
          flash[:notice] = 'Admin::OpenidIdentifier was successfully created.'
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

      respond_to do |format|
        if object.update_attributes(params[controller_name.singularize.to_sym])
          flash[:notice] = 'Admin::OpenidIdentifier was successfully updated.'
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
        format.html { redirect_to(url_for_parent) }
        format.xml  { head :ok }
      end
    end

    private
    def chiled_objects
      load_parent.send(controller_name.to_sym)
    end

    def url_for_parent_and(object)
      redirect_url = url_prefix+controller_name.singularize+"_url"
      send(redirect_url.to_sym, load_parent, object)
    end

    def url_for_parent
      redirect_url = url_prefix+controller_name+"_url"
      send(redirect_url.to_sym, load_parent)
    end
  end
end
