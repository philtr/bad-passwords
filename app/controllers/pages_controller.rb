class PagesController < ApplicationController
  def index
    @registration_user = User.new
    @login_email = ""
    @registration_result = flash[:registration_result]&.deep_symbolize_keys
    @login_result = flash[:login_result]&.deep_symbolize_keys
    @jwt_public_key = ENV["JWT_PUBLIC_KEY"].to_s
  end

  def docs
  end

  def test_password
    render plain: Rails.cache.fetch("example_password_hash") { Argon2::Password.create("test123") }
  end
end
