class Admin::UsersController < ApplicationController
  include AdminModule::AdminRootModule
  before_filter :require_admin
end
