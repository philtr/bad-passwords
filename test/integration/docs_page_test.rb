require "test_helper"

class DocsPageTest < ActionDispatch::IntegrationTest
  test "renders the docs page" do
    get "/docs"

    assert_response :success
    assert_match "Bad Passwords Docs", response.body
    assert_match "API Docs", response.body
    assert_match "POST /register", response.body
    assert_match "POST /login", response.body
  end

  test "links to the docs page from the home page" do
    get "/"

    assert_response :success
    assert_match 'href="/docs"', response.body
  end
end
