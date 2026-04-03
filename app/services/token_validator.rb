class TokenValidator
  Result = Struct.new(:success?, :payload, :user, keyword_init: true)

  def self.call(token)
    payload = JwtIssuer.decode(token)
    user = User.includes(:token_version).find_by(email: payload["sub"])

    raise JWT::DecodeError, "Invalid token version" unless user
    raise JWT::DecodeError, "Invalid token version" unless payload["ver"] == user.current_token_version

    Result.new(success?: true, payload: payload, user: user)
  end
end
