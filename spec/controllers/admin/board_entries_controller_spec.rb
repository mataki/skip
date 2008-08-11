require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BoardEntriesController do
  before do
    admin_login
  end
  describe "handling GET /admin_board_entries" do

    before(:each) do
      @board_entry = mock_model(Admin::BoardEntry)
      Admin::BoardEntry.stub!(:find).and_return([@board_entry])
    end
  
    def do_get
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should render index template" do
      do_get
      response.should render_template('index')
    end
  
    it "should find all admin_board_entries" do
      Admin::BoardEntry.should_receive(:find).with(:all).and_return([@board_entry])
      do_get
    end
  
    it "should assign the found admin_board_entries for the view" do
      do_get
      assigns[:board_entries].should == [@board_entry]
    end
  end

  describe "handling GET /admin_board_entries.xml" do

    before(:each) do
      @board_entries = mock("Array of Admin::BoardEntries", :to_xml => "XML")
      Admin::BoardEntry.stub!(:find).and_return(@board_entries)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all admin_board_entries" do
      Admin::BoardEntry.should_receive(:find).with(:all).and_return(@board_entries)
      do_get
    end
  
    it "should render the found admin_board_entries as xml" do
      @board_entries.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /admin_board_entries/1" do

    before(:each) do
      @board_entry = mock_model(Admin::BoardEntry)
      Admin::BoardEntry.stub!(:find).and_return(@board_entry)
    end
  
    def do_get
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render show template" do
      do_get
      response.should render_template('show')
    end
  
    it "should find the board_entry requested" do
      Admin::BoardEntry.should_receive(:find).with("1").and_return(@board_entry)
      do_get
    end
  
    it "should assign the found board_entry for the view" do
      do_get
      assigns[:board_entry].should equal(@board_entry)
    end
  end

  describe "handling GET /admin_board_entries/1.xml" do

    before(:each) do
      @board_entry = mock_model(Admin::BoardEntry, :to_xml => "XML")
      Admin::BoardEntry.stub!(:find).and_return(@board_entry)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the board_entry requested" do
      Admin::BoardEntry.should_receive(:find).with("1").and_return(@board_entry)
      do_get
    end
  
    it "should render the found board_entry as xml" do
      @board_entry.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /admin_board_entries/new" do

    before(:each) do
      @board_entry = mock_model(Admin::BoardEntry)
      Admin::BoardEntry.stub!(:new).and_return(@board_entry)
    end
  
    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render new template" do
      do_get
      response.should render_template('new')
    end
  
    it "should create an new board_entry" do
      Admin::BoardEntry.should_receive(:new).and_return(@board_entry)
      do_get
    end
  
    it "should not save the new board_entry" do
      @board_entry.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new board_entry for the view" do
      do_get
      assigns[:board_entry].should equal(@board_entry)
    end
  end

  describe "handling GET /admin_board_entries/1/edit" do

    before(:each) do
      @board_entry = mock_model(Admin::BoardEntry)
      Admin::BoardEntry.stub!(:find).and_return(@board_entry)
    end
  
    def do_get
      get :edit, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should render edit template" do
      do_get
      response.should render_template('edit')
    end
  
    it "should find the board_entry requested" do
      Admin::BoardEntry.should_receive(:find).and_return(@board_entry)
      do_get
    end
  
    it "should assign the found Admin::BoardEntry for the view" do
      do_get
      assigns[:board_entry].should equal(@board_entry)
    end
  end

  describe "handling POST /admin_board_entries" do

    before(:each) do
      @board_entry = mock_model(Admin::BoardEntry, :to_param => "1")
      Admin::BoardEntry.stub!(:new).and_return(@board_entry)
    end
    
    describe "with successful save" do
  
      def do_post
        @board_entry.should_receive(:save).and_return(true)
        post :create, :admin_board_entry => {}
      end
  
      it "should create a new board_entry" do
        Admin::BoardEntry.should_receive(:new).with({}).and_return(@board_entry)
        do_post
      end

      it "should redirect to the new board_entry" do
        do_post
        response.should redirect_to(admin_board_entry_url("1"))
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @board_entry.should_receive(:save).and_return(false)
        post :create, :board_entry => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /admin_board_entries/1" do

    before(:each) do
      @board_entry = mock_model(Admin::BoardEntry, :to_param => "1")
      Admin::BoardEntry.stub!(:find).and_return(@board_entry)
    end
    
    describe "with successful update" do

      def do_put
        @board_entry.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the board_entry requested" do
        Admin::BoardEntry.should_receive(:find).with("1").and_return(@board_entry)
        do_put
      end

      it "should update the found board_entry" do
        do_put
        assigns(:board_entry).should equal(@board_entry)
      end

      it "should assign the found board_entry for the view" do
        do_put
        assigns(:board_entry).should equal(@board_entry)
      end

      it "should redirect to the board_entry" do
        do_put
        response.should redirect_to(admin_board_entry_url("1"))
      end

    end
    
    describe "with failed update" do

      def do_put
        @board_entry.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /admin_board_entries/1" do

    before(:each) do
      @board_entry = mock_model(Admin::BoardEntry, :destroy => true)
      Admin::BoardEntry.stub!(:find).and_return(@board_entry)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the board_entry requested" do
      Admin::BoardEntry.should_receive(:find).with("1").and_return(@board_entry)
      do_delete
    end
  
    it "should call destroy on the found board_entry" do
      @board_entry.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the admin_board_entries list" do
      do_delete
      response.should redirect_to(admin_board_entries_url)
    end
  end
end
