require "net/http"

class RemotePasswordVerifier
  class Result
    attr_reader :status, :message, :password_hash

    def initialize(status:, message:, password_hash: nil)
      @status = status
      @message = message
      @password_hash = password_hash
    end

    def success?
      status == :success
    end

    def invalid_credentials?
      status == :invalid_credentials
    end
  end

  def initialize(password:, password_hash_url:)
    @password = password.to_s
    @password_hash_url = password_hash_url.to_s
  end

  def call
    uri = URI.parse(password_hash_url)
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      return Result.new(status: :fetch_error, message: "Could not fetch password hash URL.")
    end

    password_hash = response.body.to_s.strip
    return Result.new(status: :invalid_hash, message: "Password hash URL did not return an Argon2 hash.") if password_hash.empty?

    if Argon2::Password.verify_password(password, password_hash)
      Result.new(status: :success, message: "Password verified.", password_hash: password_hash)
    else
      Result.new(status: :invalid_credentials, message: "Password does not match the remote Argon2 hash.")
    end
  rescue URI::InvalidURIError
    Result.new(status: :invalid_url, message: "Password hash URL is invalid.")
  rescue Argon2::ArgonHashFail
    Result.new(status: :invalid_hash, message: "Password hash URL did not return an Argon2 hash.")
  rescue StandardError
    Result.new(status: :fetch_error, message: "Could not fetch password hash URL.")
  end

  private

  attr_reader :password, :password_hash_url
end
