class TokensController < ApplicationController
  INVALID_TOKEN_MESSAGE = "Invalid token.".freeze

  def new
    @token = ""
    @validation_result = flash[:validation_result]&.deep_symbolize_keys
  end

  def validate
    token = bearer_token || token_param
    return respond_with_invalid_token unless token.present?

    payload = JwtIssuer.decode(token)

    respond_with_validation_result(payload)
  rescue JWT::DecodeError
    respond_with_invalid_token
  end

  private

  def bearer_token
    authenticate_with_http_token do |token, _options|
      token
    end
  end

  def token_param
    params[:token].to_s.strip
  end

  def respond_with_validation_result(payload)
    validation_result = {
      success: true,
      message: "Token is valid.",
      token: token_param,
      payload: payload
    }

    respond_to do |format|
      format.html do
        flash[:validation_result] = validation_result
        redirect_to validate_path, status: :see_other
      end
      format.json { render json: { valid: true, payload: payload }, status: :ok }
    end
  end

  def respond_with_invalid_token
    validation_result = {
      success: false,
      message: INVALID_TOKEN_MESSAGE,
      token: token_param
    }

    respond_to do |format|
      format.html do
        flash[:validation_result] = validation_result
        redirect_to validate_path, status: :see_other
      end
      format.json { render json: { valid: false, error: INVALID_TOKEN_MESSAGE }, status: :unauthorized }
    end
  end
end
