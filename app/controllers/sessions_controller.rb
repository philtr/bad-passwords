class SessionsController < ApplicationController
  def create
    @registration_user = User.new
    @login_email = login_params[:email].to_s
    @registration_result = nil
    @login_result = nil

    user = User.find_by(email: login_params[:email])
    return respond_with_login_result(false, "Unknown email address.") unless user

    verification = RemotePasswordVerifier.new(
      password: login_params[:password],
      password_hash_url: user.password_hash_url
    ).call
    return respond_with_login_result(false, verification.message) unless verification.success?

    token = JwtIssuer.new(user: user).call
    decoded_token = JwtIssuer.decode(token)

    @login_result = {
      success: true,
      message: "Login succeeded.",
      email: user.email,
      token: token,
      decoded_token: decoded_token
    }

    respond_to do |format|
      format.html do
        flash[:login_result] = @login_result
        redirect_to root_path, status: :see_other
      end
      format.json { render json: { token: token, token_type: "Bearer", email: user.email }, status: :ok }
    end
  end

  private

  def login_params
    params.permit(:email, :password)
  end

  def respond_with_login_result(success, message)
    @login_result = {
      success: success,
      message: message
    }

    respond_to do |format|
      format.html do
        flash[:login_result] = @login_result
        redirect_to root_path, status: :see_other
      end
      format.json { render json: { error: message }, status: :unprocessable_entity }
    end
  end
end
