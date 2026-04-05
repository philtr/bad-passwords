require "test_helper"

class DocsPageTest < ActionDispatch::IntegrationTest
  test "renders the docs page" do
    get "/docs"

    assert_response :success
    assert_match "Bad Passwords Docs", response.body
    assert_match 'href="/">Home</a>', response.body
    assert_match 'aria-current="page">Docs</span>', response.body
    assert_match 'href="/faq">FAQ</a>', response.body
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

  test "renders the faq page" do
    get "/faq"

    assert_response :success
    assert_match "Bad Passwords FAQ", response.body
    assert_match "Contents", response.body
    assert_match 'href="#what-is-this"', response.body
    assert_match 'href="#login-flow"', response.body
    assert_match 'href="#public-hash"', response.body
    assert_match 'href="#why-argon2"', response.body
    assert_match "What is this thing, actually?", response.body
    assert_match "So when I log in, what happens?", response.body
    assert_match "Why Argon2, and what does “hard to crack” look like in numbers?", response.body
    assert_match "<strong>1,536 guesses per second</strong>", response.body
    assert_match "<strong>8.7 million years</strong>", response.body
    assert_match "<strong>4.9 x 10<sup>17</sup> years</strong>", response.body
    assert_match 'href="#contents">Back to contents</a>', response.body
    assert_match 'href="/">Home</a>', response.body
    assert_match 'href="/docs">Docs</a>', response.body
    assert_match 'aria-current="page">FAQ</span>', response.body
    assert_match 'href="/validate">Validate</a>', response.body
  end

  test "links to the docs page from the home page" do
    get "/"

    assert_response :success
    assert_match "Bad Passwords handles delegated password verification.", response.body
    assert_match "Your password hash URL should return the plaintext Argon2 hash", response.body
    assert_match 'aria-current="page">Home</span>', response.body
    assert_match 'href="/docs"', response.body
    assert_match 'href="/faq"', response.body
    assert_match 'href="/validate"', response.body
  end
end
