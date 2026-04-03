class RegistrationsController < ApplicationController
  PASSWORD_HASH_VERIFICATION_ERROR_MESSAGE = "Could not verify the password hash URL.".freeze

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
        message: verification.success? ? @registration_user.errors.full_messages.to_sentence : registration_error_message(verification)
      }
    end

    respond_to do |format|
      format.html do
        flash[:registration_result] = @registration_result
        redirect_to root_path, status: :see_other
      end
      format.json do
        if @registration_result[:success]
          render json: { email: @registration_user.email, password_hash_url: @registration_user.password_hash_url }, status: :created
        else
          render json: { error: @registration_result[:message] }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def registration_params
    params.permit(:email, :password_hash_url, :password)
  end

  def registration_error_message(verification)
    return verification.message unless infrastructure_verification_error?(verification)

    Rails.logger.warn("Password hash verification failed during registration: #{verification.message}")
    PASSWORD_HASH_VERIFICATION_ERROR_MESSAGE
  end

  def infrastructure_verification_error?(verification)
    verification.status.in?([ :fetch_error, :invalid_hash, :invalid_url ])
  end
end
