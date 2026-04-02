class PagesController < ApplicationController
  def index
    @registration_user = User.new
    @login_email = ""
    @registration_result = flash[:registration_result]&.deep_symbolize_keys
    @login_result = flash[:login_result]&.deep_symbolize_keys
  end

  def test_password
    render plain: Argon2::Password.create("test123")
  end
end
