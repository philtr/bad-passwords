class TokensController < ApplicationController
  INVALID_TOKEN_MESSAGE = "Invalid token.".freeze

  def new
    @token = ""
    @validation_result = flash[:validation_result]&.deep_symbolize_keys
  end

  def validate
    @token = token_param
    token = bearer_token || token_param
    return respond_with_invalid_token unless token.present?

    result = TokenValidator.call(token)

    respond_with_validation_result(result.payload)
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
      token: @token,
      payload: payload
    }

    respond_to do |format|
      format.html do
        @validation_result = validation_result
        render :new, status: :ok
      end
      format.json { render json: { valid: true, payload: payload }, status: :ok }
    end
  end

  def respond_with_invalid_token
    validation_result = {
      success: false,
      message: INVALID_TOKEN_MESSAGE,
      token: @token
    }

    respond_to do |format|
      format.html do
        @validation_result = validation_result
        render :new, status: :unauthorized
      end
      format.json { render json: { valid: false, error: INVALID_TOKEN_MESSAGE }, status: :unauthorized }
    end
  end
end
