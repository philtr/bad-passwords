require "test_helper"

class TokenValidatorTest < ActiveSupport::TestCase
  setup do
    Rails.configuration.x.jwt.issuer = "bad-passwords-test"
    JwtIssuer.reset_keys!
  end

  test "rejects a token whose subject does not map to a user" do
    token = JWT.encode(
      {
        "sub" => "missing@example.com",
        "iss" => "bad-passwords-test",
        "ver" => "token-version",
        "iat" => Time.current.to_i,
        "exp" => 1.hour.from_now.to_i
      },
      JwtIssuer.private_key,
      "RS256"
    )

    assert_raises(JWT::DecodeError) do
      TokenValidator.call(token)
    end
  end
end
