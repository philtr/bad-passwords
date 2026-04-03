require "test_helper"

class DocsPageTest < ActionDispatch::IntegrationTest
  test "renders the docs page" do
    get "/docs"

    assert_response :success
    assert_match "Bad Passwords Docs", response.body
    assert_match 'href="/">Home</a>', response.body
    assert_match 'aria-current="page">Docs</span>', response.body
    assert_match 'href="/validate">Validate</a>', response.body
    assert_match "API Docs", response.body
    assert_match "POST /register", response.body
    assert_match "POST /login", response.body
    assert_match "POST /validate", response.body
    assert_match "DELETE /logout", response.body
  end

  test "links to the docs page from the home page" do
    get "/"

    assert_response :success
    assert_match "Bad Passwords handles delegated password verification.", response.body
    assert_match "Your password hash URL should return the plaintext Argon2 hash", response.body
    assert_match 'aria-current="page">Home</span>', response.body
    assert_match 'href="/docs"', response.body
    assert_match 'href="/validate"', response.body
  end
end
