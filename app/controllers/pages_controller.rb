class PagesController < ApplicationController
  def index
    @registration_user = User.new
    @login_email = ""
    @registration_result = nil
    @login_result = nil
  end
end
