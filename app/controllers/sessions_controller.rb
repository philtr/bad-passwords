class SessionsController < ApplicationController
  INVALID_CREDENTIALS_MESSAGE = "Invalid email or password.".freeze

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

    respond_with_result(
      flash_key: :login_result,
      result: @login_result,
      success_payload: { token: token, token_type: "Bearer", email: user.email },
      success_status: :ok
    )
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

    respond_with_result(
      flash_key: :login_result,
      result: @login_result,
      success_payload: {},
      success_status: :ok
    )
  end
end
