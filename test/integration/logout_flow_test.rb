require "test_helper"

class LogoutFlowTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.x.jwt.issuer = "bad-passwords-test"
    JwtIssuer.reset_keys!
    @password = "correct horse battery staple"
    @hash = Argon2::Password.create(@password)
    @user = User.create!(email: "user@example.com", password_hash_url: "https://example.com/hash.txt")
    @token = JwtIssuer.new(user: @user).call
    stub_request(:get, "https://example.com/hash.txt").to_return(status: 200, body: @hash)
  end

  test "logs out with a valid token and invalidates prior tokens" do
    old_version = @user.current_token_version

    delete "/logout", headers: { "Authorization" => "Bearer #{@token}" }, as: :json

    assert_response :success
    assert_equal "user@example.com", JSON.parse(response.body)["email"]

    @user.reload
    assert_not_equal old_version, @user.current_token_version

    post "/validate", params: { token: @token }, as: :json
    assert_response :unauthorized
  end

  test "logs out with credentials and invalidates prior tokens" do
    old_version = @user.current_token_version

    delete "/logout", params: { username: "user@example.com", password: @password }, as: :json

    assert_response :success
    assert_equal "user@example.com", JSON.parse(response.body)["email"]

    @user.reload
    assert_not_equal old_version, @user.current_token_version

    post "/validate", params: { token: @token }, as: :json
    assert_response :unauthorized
  end

  test "rejects logout with invalid credentials" do
    delete "/logout", params: { email: "user@example.com", password: "wrong password" }, as: :json

    assert_response :unauthorized
    assert_equal({ "error" => "Invalid token or credentials." }, JSON.parse(response.body))
  end

  test "rejects logout with an invalid token" do
    delete "/logout", headers: { "Authorization" => "Bearer not-a-jwt" }, as: :json

    assert_response :unauthorized
    assert_equal({ "error" => "Invalid token or credentials." }, JSON.parse(response.body))
  end
end
