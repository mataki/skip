class Admin::BoardEntriesController < ApplicationController
  include AdminModule::AdminRootModule
  before_filter :require_admin
end
