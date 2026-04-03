class RegistrationsController < ApplicationController
  def create
    @registration_user = User.new(registration_params.except(:password))
    @login_email = ""
    @registration_result = nil
    @login_result = nil

    verification = RemotePasswordVerifier.new(
      password: registration_params[:password],
      password_hash_url: registration_params[:password_hash_url]
    ).call

    if verification.success? && @registration_user.save
      @registration_result = {
        success: true,
        message: "Registration succeeded."
      }
    else
      @registration_result = {
        success: false,
        message: verification.success? ? @registration_user.errors.full_messages.to_sentence : verification.message
      }
    end

    respond_with_result(
      flash_key: :registration_result,
      result: @registration_result,
      success_payload: { email: @registration_user.email, password_hash_url: @registration_user.password_hash_url },
      success_status: :created
    )
  end

  private

  def registration_params
    params.permit(:email, :password_hash_url, :password)
  end
end
