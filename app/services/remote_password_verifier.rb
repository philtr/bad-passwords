require "net/http"

class RemotePasswordVerifier
  FETCH_ERROR_MESSAGE = "Could not fetch password hash URL.".freeze
  INVALID_HASH_MESSAGE = "Password hash URL did not return an Argon2 hash.".freeze
  INVALID_URL_MESSAGE = "Password hash URL is invalid.".freeze
  INVALID_CREDENTIALS_MESSAGE = "Password does not match the remote Argon2 hash.".freeze
  SUCCESS_MESSAGE = "Password verified.".freeze

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
    password_hash = fetch_password_hash
    return password_hash unless password_hash.is_a?(String)

    verify_password_hash(password_hash)
  rescue URI::InvalidURIError
    result(:invalid_url, INVALID_URL_MESSAGE)
  rescue Argon2::ArgonHashFail
    result(:invalid_hash, INVALID_HASH_MESSAGE)
  rescue StandardError
    result(:fetch_error, FETCH_ERROR_MESSAGE)
  end

  private

  attr_reader :password, :password_hash_url

  def fetch_password_hash
    response = Net::HTTP.get_response(URI.parse(password_hash_url))
    return result(:fetch_error, FETCH_ERROR_MESSAGE) unless response.is_a?(Net::HTTPSuccess)

    password_hash = response.body.to_s.strip
    return result(:invalid_hash, INVALID_HASH_MESSAGE) if password_hash.empty?

    password_hash
  end

  def verify_password_hash(password_hash)
    if Argon2::Password.verify_password(password, password_hash)
      result(:success, SUCCESS_MESSAGE, password_hash:)
    else
      result(:invalid_credentials, INVALID_CREDENTIALS_MESSAGE)
    end
  end

  def result(status, message, password_hash: nil)
    Result.new(status:, message:, password_hash:)
  end
end
