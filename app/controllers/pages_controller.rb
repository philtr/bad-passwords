class PagesController < ApplicationController
  def index
    @registration_user = User.new
    @login_email = ""
    @registration_result = nil
    @login_result = nil
  end

  def test_password
    render plain: Argon2::Password.create("test123")
  end
end
