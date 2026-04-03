class SessionsController < ApplicationController
  INVALID_CREDENTIALS_MESSAGE = "Invalid email or password.".freeze
  INVALID_TOKEN_MESSAGE = "Invalid token.".freeze
  INVALID_LOGOUT_MESSAGE = "Invalid token or credentials.".freeze

  def create
    @registration_user = User.new
    @login_email = login_params[:email].to_s
    @registration_result = nil
    @login_result = nil

    user = User.find_by(email: login_params[:email])
    return respond_with_login_result(false, INVALID_CREDENTIALS_MESSAGE) unless user

    verification = RemotePasswordVerifier.new(
      password: login_params[:password],
      password_hash_url: user.password_hash_url
    ).call
    if verification.invalid_credentials?
      return respond_with_login_result(false, INVALID_CREDENTIALS_MESSAGE)
    end

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

  def destroy
    user = logout_user_from_token || logout_user_from_credentials
    return respond_with_logout_failure unless user

    user.rotate_token_version!
    @login_result = {
      success: true,
      message: "Logout succeeded. Existing tokens revoked.",
      email: user.email
    }

    respond_to do |format|
      format.html do
        flash[:login_result] = @login_result
        redirect_to root_path, status: :see_other
      end
      format.json { render json: { success: true, email: user.email }, status: :ok }
    end
  end

  private

  def login_params
    params.permit(:email, :password)
  end

  def logout_params
    params.permit(:email, :username, :password)
  end

  def logout_user_from_token
    token = authenticate_with_http_token { |value, _options| value }
    return unless token.present?

    TokenValidator.call(token).user
  rescue JWT::DecodeError
    nil
  end

  def logout_user_from_credentials
    identifier = logout_params[:email].presence || logout_params[:username].presence
    return unless identifier.present? && logout_params[:password].present?

    user = User.find_by(email: identifier)
    return unless user

    verification = RemotePasswordVerifier.new(
      password: logout_params[:password],
      password_hash_url: user.password_hash_url
    ).call

    verification.success? ? user : nil
  end

  def respond_with_logout_failure
    @login_result = {
      success: false,
      message: INVALID_LOGOUT_MESSAGE
    }

    respond_to do |format|
      format.html do
        flash[:login_result] = @login_result
        redirect_to root_path, status: :see_other
      end
      format.json { render json: { error: INVALID_LOGOUT_MESSAGE }, status: :unauthorized }
    end
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
