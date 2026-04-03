class JwtIssuer
  TTL = 1.hour

  def initialize(user:)
    @user = user
  end

  def call
    JWT.encode(payload, private_key, "RS256")
  end

  def self.decode(token)
    payload, = JWT.decode(token, public_key, true, algorithm: "RS256", verify_iss: true, iss: issuer)
    payload
  end

  def self.private_key
    @private_key ||= OpenSSL::PKey::RSA.new(normalized_key(private_key_pem))
  end

  def self.public_key
    @public_key ||= OpenSSL::PKey::RSA.new(normalized_key(public_key_pem))
  end

  def self.reset_keys!
    @private_key = nil
    @public_key = nil
  end

  def self.normalized_key(key)
    key.gsub("\\n", "\n")
  end

  def self.private_key_pem
    Rails.configuration.x.jwt.private_key.presence || raise(KeyError, 'key not found: "JWT_PRIVATE_KEY"')
  end

  def self.public_key_pem
    Rails.configuration.x.jwt.public_key.presence || raise(KeyError, 'key not found: "JWT_PUBLIC_KEY"')
  end

  def self.issuer
    Rails.configuration.x.jwt.issuer
  end

  private

  attr_reader :user

  def payload
    issued_at = Time.current.to_i

    {
      "sub" => user.email,
      "iss" => self.class.issuer,
      "ver" => user.current_token_version,
      "iat" => issued_at,
      "exp" => issued_at + TTL.to_i
    }
  end

  def private_key
    self.class.private_key
  end
end
