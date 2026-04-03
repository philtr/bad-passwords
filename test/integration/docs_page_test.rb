require "test_helper"

class DocsPageTest < ActionDispatch::IntegrationTest
  test "renders the docs page" do
    get "/docs"

    assert_response :success
    assert_match "Bad Passwords Docs", response.body
    assert_no_match 'alt="Bad Passwords"', response.body
    assert_match 'href="/">Home</a>', response.body
    assert_match 'aria-current="page">Docs</span>', response.body
    assert_match 'href="/validate">Validate</a>', response.body
    assert_match "API Docs", response.body
    assert_match "Contents", response.body
    assert_match 'href="#register"', response.body
    assert_match 'href="#login"', response.body
    assert_match 'href="#validate"', response.body
    assert_match 'href="#logout"', response.body
    assert_match "POST /register", response.body
    assert_match "POST /login", response.body
    assert_match "POST /validate", response.body
    assert_match "DELETE /logout", response.body
  end

  test "renders social metadata for the docs page" do
    get "/docs"

    assert_response :success
    assert_match '<meta name="description" content="Read the Bad Passwords API docs for delegated password verification, login, JWT validation, and logout endpoints.">', response.body
    assert_match '<link rel="canonical" href="http://www.example.com/docs">', response.body
    assert_match '<meta property="og:title" content="Bad Passwords Docs">', response.body
    assert_match '<meta property="og:url" content="http://www.example.com/docs">', response.body
    assert_match '<meta property="og:image" content="http://www.example.com/images/preview.png">', response.body
    assert_match '<meta name="twitter:card" content="summary">', response.body
  end

  test "links to the docs page from the home page" do
    get "/"

    assert_response :success
    assert_match "Bad Passwords handles delegated password verification.", response.body
    assert_match "Your password hash URL should return the plaintext Argon2 hash", response.body
    assert_match 'alt="Bad Passwords"', response.body
    assert_match 'aria-current="page">Home</span>', response.body
    assert_match 'href="/docs"', response.body
    assert_match 'href="/validate"', response.body
  end

  test "renders social metadata for the home page" do
    get "/"

    assert_response :success
    assert_match '<meta name="description" content="Bad Passwords handles delegated password verification with remote Argon2 hashes, JWT issuance, and browser-based testing tools.">', response.body
    assert_match '<link rel="canonical" href="http://www.example.com/">', response.body
    assert_match '<meta property="og:title" content="Bad Passwords">', response.body
    assert_match '<meta property="og:url" content="http://www.example.com/">', response.body
    assert_match '<meta property="og:image" content="http://www.example.com/images/preview.png">', response.body
    assert_match '<meta name="twitter:title" content="Bad Passwords">', response.body
  end
end
