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
end
