class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery unless: -> { request.format.json? }

  rate_limit to: 60, within: 1.minute, by: -> { request.remote_ip }, with: :render_rate_limited

  private

  def render_rate_limited
    respond_to do |format|
      format.html { render plain: "Too many requests.", status: :too_many_requests }
      format.json { render json: { error: "Too many requests." }, status: :too_many_requests }
      format.any { render plain: "Too many requests.", status: :too_many_requests }
    end
  end
end
