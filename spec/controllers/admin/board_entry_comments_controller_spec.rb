require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BoardEntryCommentsController do
  before do
    admin_login
    @board_entry = mock_model(Admin::BoardEntry, :to_param => "1")
    controller.stub!(:load_board_entry).and_return(@board_entry)
  end
  describe "handling GET /admin_board_entry_comments" do

    before(:each) do
      @board_entry_comment = mock_model(Admin::BoardEntryComment)
      Admin::BoardEntryComment.stub!(:find).and_return([@board_entry_comment])
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
  
    it "should find all admin_board_entry_comments" do
      Admin::BoardEntryComment.should_receive(:find).with(:all).and_return([@board_entry_comment])
      do_get
    end
  
    it "should assign the found admin_board_entry_comments for the view" do
      do_get
      assigns[:board_entry_comments].should == [@board_entry_comment]
    end
  end

  describe "handling GET /admin_board_entry_comments.xml" do

    before(:each) do
      @board_entry_comments = mock("Array of Admin::BoardEntryComments", :to_xml => "XML")
      Admin::BoardEntryComment.stub!(:find).and_return(@board_entry_comments)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end
  
    it "should be successful" do
      do_get
      response.should be_success
    end

    it "should find all admin_board_entry_comments" do
      Admin::BoardEntryComment.should_receive(:find).with(:all).and_return(@board_entry_comments)
      do_get
    end
  
    it "should render the found admin_board_entry_comments as xml" do
      @board_entry_comments.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /admin_board_entry_comments/1" do

    before(:each) do
      @board_entry_comment = mock_model(Admin::BoardEntryComment)
      Admin::BoardEntryComment.stub!(:find).and_return(@board_entry_comment)
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
  
    it "should find the board_entry_comment requested" do
      Admin::BoardEntryComment.should_receive(:find).with("1").and_return(@board_entry_comment)
      do_get
    end
  
    it "should assign the found board_entry_comment for the view" do
      do_get
      assigns[:board_entry_comment].should equal(@board_entry_comment)
    end
  end

  describe "handling GET /admin_board_entry_comments/1.xml" do

    before(:each) do
      @board_entry_comment = mock_model(Admin::BoardEntryComment, :to_xml => "XML")
      Admin::BoardEntryComment.stub!(:find).and_return(@board_entry_comment)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, :id => "1"
    end

    it "should be successful" do
      do_get
      response.should be_success
    end
  
    it "should find the board_entry_comment requested" do
      Admin::BoardEntryComment.should_receive(:find).with("1").and_return(@board_entry_comment)
      do_get
    end
  
    it "should render the found board_entry_comment as xml" do
      @board_entry_comment.should_receive(:to_xml).and_return("XML")
      do_get
      response.body.should == "XML"
    end
  end

  describe "handling GET /admin_board_entry_comments/new" do

    before(:each) do
      @board_entry_comment = mock_model(Admin::BoardEntryComment)
      Admin::BoardEntryComment.stub!(:new).and_return(@board_entry_comment)
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
  
    it "should create an new board_entry_comment" do
      Admin::BoardEntryComment.should_receive(:new).and_return(@board_entry_comment)
      do_get
    end
  
    it "should not save the new board_entry_comment" do
      @board_entry_comment.should_not_receive(:save)
      do_get
    end
  
    it "should assign the new board_entry_comment for the view" do
      do_get
      assigns[:board_entry_comment].should equal(@board_entry_comment)
    end
  end

  describe "handling GET /admin_board_entry_comments/1/edit" do

    before(:each) do
      @board_entry_comment = mock_model(Admin::BoardEntryComment)
      Admin::BoardEntryComment.stub!(:find).and_return(@board_entry_comment)
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
  
    it "should find the board_entry_comment requested" do
      Admin::BoardEntryComment.should_receive(:find).and_return(@board_entry_comment)
      do_get
    end
  
    it "should assign the found Admin::BoardEntryComment for the view" do
      do_get
      assigns[:board_entry_comment].should equal(@board_entry_comment)
    end
  end

  describe "handling POST /admin_board_entry_comments" do

    before(:each) do
      @board_entry_comment = mock_model(Admin::BoardEntryComment, :to_param => "1")
      Admin::BoardEntryComment.stub!(:new).and_return(@board_entry_comment)
    end
    
    describe "with successful save" do
  
      def do_post
        @board_entry_comment.should_receive(:save).and_return(true)
        post :create, :admin_board_entry_comment => {}
      end
  
      it "should create a new board_entry_comment" do
        Admin::BoardEntryComment.should_receive(:new).with({}).and_return(@board_entry_comment)
        do_post
      end

      it "should redirect to the new board_entry_comment" do
        do_post
        response.should redirect_to(admin_board_entry_board_entry_comment_url(@board_entry, @board_entry_comment))
      end
      
    end
    
    describe "with failed save" do

      def do_post
        @board_entry_comment.should_receive(:save).and_return(false)
        post :create, :board_entry_comment => {}
      end
  
      it "should re-render 'new'" do
        do_post
        response.should render_template('new')
      end
      
    end
  end

  describe "handling PUT /admin_board_entry_comments/1" do

    before(:each) do
      @board_entry_comment = mock_model(Admin::BoardEntryComment, :to_param => "1")
      Admin::BoardEntryComment.stub!(:find).and_return(@board_entry_comment)
    end
    
    describe "with successful update" do

      def do_put
        @board_entry_comment.should_receive(:update_attributes).and_return(true)
        put :update, :id => "1"
      end

      it "should find the board_entry_comment requested" do
        Admin::BoardEntryComment.should_receive(:find).with("1").and_return(@board_entry_comment)
        do_put
      end

      it "should update the found board_entry_comment" do
        do_put
        assigns(:board_entry_comment).should equal(@board_entry_comment)
      end

      it "should assign the found board_entry_comment for the view" do
        do_put
        assigns(:board_entry_comment).should equal(@board_entry_comment)
      end

      it "should redirect to the board_entry_comment" do
        do_put
        response.should redirect_to(admin_board_entry_board_entry_comment_path(@board_entry, @board_entry_comment))
      end

    end
    
    describe "with failed update" do

      def do_put
        @board_entry_comment.should_receive(:update_attributes).and_return(false)
        put :update, :id => "1"
      end

      it "should re-render 'edit'" do
        do_put
        response.should render_template('edit')
      end

    end
  end

  describe "handling DELETE /admin_board_entry_comments/1" do

    before(:each) do
      @board_entry_comment = mock_model(Admin::BoardEntryComment, :destroy => true)
      Admin::BoardEntryComment.stub!(:find).and_return(@board_entry_comment)
    end
  
    def do_delete
      delete :destroy, :id => "1"
    end

    it "should find the board_entry_comment requested" do
      Admin::BoardEntryComment.should_receive(:find).with("1").and_return(@board_entry_comment)
      do_delete
    end
  
    it "should call destroy on the found board_entry_comment" do
      @board_entry_comment.should_receive(:destroy)
      do_delete
    end
  
    it "should redirect to the admin_board_entry_comments list" do
      do_delete
      response.should redirect_to(admin_board_entry_board_entry_comments_path(@board_entry))
    end
  end
end
