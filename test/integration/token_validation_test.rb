require "test_helper"

class TokenValidationTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.x.jwt.issuer = "bad-passwords-test"
    JwtIssuer.reset_keys!
    @user = User.create!(email: "user@example.com", password_hash_url: "https://example.com/hash.txt")
    @token = JwtIssuer.new(user: @user).call
  end

  test "validates a token from the json body" do
    post "/validate", params: { token: @token }, as: :json

    assert_response :success

    body = JSON.parse(response.body)

    assert_equal true, body["valid"]
    assert_equal "user@example.com", body.dig("payload", "sub")
    assert_equal "bad-passwords-test", body.dig("payload", "iss")
    assert_equal @user.current_token_version, body.dig("payload", "ver")
  end

  test "validates a token from the authorization header" do
    post "/validate", headers: { "Authorization" => "Bearer #{@token}" }, as: :json

    assert_response :success
    assert_equal true, JSON.parse(response.body)["valid"]
  end

  test "renders the token validation page" do
    get "/validate"

    assert_response :success
    assert_match "Validate Token", response.body
    assert_match 'textarea id="token"', response.body
  end

  test "renders a successful html validation result" do
    post "/validate", params: { token: @token }

    assert_redirected_to "/validate"

    follow_redirect!
    assert_response :success
    assert_match "Token is valid.", response.body
    assert_match "Decoded Token", response.body
    assert_match "user@example.com", response.body
  end

  test "rejects an invalid token" do
    post "/validate", params: { token: "not-a-jwt" }, as: :json

    assert_response :unauthorized
    assert_equal({ "valid" => false, "error" => "Invalid token." }, JSON.parse(response.body))
  end

  test "rejects a token with a stale version" do
    @user.rotate_token_version!

    post "/validate", params: { token: @token }, as: :json

    assert_response :unauthorized
    assert_equal({ "valid" => false, "error" => "Invalid token." }, JSON.parse(response.body))
  end

  test "rejects a token with the wrong issuer" do
    token = JWT.encode(
      {
        "sub" => @user.email,
        "iss" => "bad-passwords-other",
        "ver" => @user.current_token_version,
        "iat" => Time.current.to_i,
        "exp" => 1.hour.from_now.to_i
      },
      JwtIssuer.private_key,
      "RS256"
    )

    post "/validate", params: { token: token }, as: :json

    assert_response :unauthorized
    assert_equal({ "valid" => false, "error" => "Invalid token." }, JSON.parse(response.body))
  end

  test "rejects a missing token" do
    post "/validate", params: {}, as: :json

    assert_response :unauthorized
    assert_equal({ "valid" => false, "error" => "Invalid token." }, JSON.parse(response.body))
  end

  test "renders an invalid html validation result" do
    post "/validate", params: { token: "not-a-jwt" }

    assert_redirected_to "/validate"

    follow_redirect!
    assert_response :success
    assert_match "Invalid token.", response.body
  end
end
