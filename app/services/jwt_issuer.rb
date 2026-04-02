class JwtIssuer
  TTL = 1.hour

  def initialize(user:)
    @user = user
  end

  def call
    JWT.encode(payload, secret, "HS256")
  end

  def self.decode(token)
    payload, = JWT.decode(token, secret, true, algorithm: "HS256")
    payload
  end

  def self.secret
    Rails.application.secret_key_base
  end

  private

  attr_reader :user

  def payload
    issued_at = Time.current.to_i

    {
      "sub" => user.email,
      "email" => user.email,
      "iss" => ENV.fetch("JWT_ISSUER"),
      "iat" => issued_at,
      "exp" => issued_at + TTL.to_i
    }
  end

  def secret
    self.class.secret
  end
end
