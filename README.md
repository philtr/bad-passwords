# Bad Passwords

Small Rails app for testing a simple SSO flow against a remotely hosted plaintext Argon2 hash.

## What It Does

1. Register a user with:
   - `email`
   - `password_hash_url`
   - plaintext `password`
2. On registration, the app fetches the remote hash and verifies the submitted password matches it.
3. On login, the app fetches the current hash from the stored URL and verifies the submitted password again.
4. If login succeeds, the app returns a signed JWT.

The app supports:

- bare HTML forms at `/`
- JSON API requests to `POST /register` and `POST /login`
- a login test page that shows the token and decoded token payload

## Requirements

- Ruby 4.x
- Rails 8.x
- SQLite

## Setup

Install dependencies:

```bash
bundle install
```

Prepare the database:

```bash
bin/rails db:prepare
```

Set the JWT issuer:

```bash
export JWT_ISSUER=bad-passwords-dev
```

Set the JWT signing keypair:

```bash
export JWT_PRIVATE_KEY="$(cat path/to/jwt_private.pem)"
export JWT_PUBLIC_KEY="$(cat path/to/jwt_public.pem)"
```

Start the server:

```bash
bin/rails server
```

Then open:

- [http://127.0.0.1:3000](http://127.0.0.1:3000)

## HTML UI

The home page provides:

- a registration form
- a login test form
- result tables for success and failure
- API docs below the forms

Layout is plain HTML with tables. There is no CSS layout system.

## JSON API

For JSON requests, send:

- `Content-Type: application/json`
- `Accept: application/json`

### `POST /register`

Request body:

```json
{
  "email": "user@example.com",
  "password_hash_url": "https://example.com/hash.txt",
  "password": "correct horse battery staple"
}
```

Successful response:

```json
{
  "email": "user@example.com",
  "password_hash_url": "https://example.com/hash.txt"
}
```

Error response:

```json
{
  "error": "Password does not match the remote Argon2 hash."
}
```

### `POST /login`

Request body:

```json
{
  "email": "user@example.com",
  "password": "correct horse battery staple"
}
```

Successful response:

```json
{
  "token": "JWT_TOKEN_HERE",
  "token_type": "Bearer",
  "email": "user@example.com"
}
```

Error response:

```json
{
  "error": "Invalid email or password."
}
```

## Curl Examples

Register:

```bash
curl -i http://127.0.0.1:3000/register \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{
    "email": "user@example.com",
    "password_hash_url": "https://example.com/hash.txt",
    "password": "correct horse battery staple"
  }'
```

Login:

```bash
curl -i http://127.0.0.1:3000/login \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{
    "email": "user@example.com",
    "password": "correct horse battery staple"
  }'
```

## JWT

Successful login returns an RS256-signed JWT using the keypair from `JWT_PRIVATE_KEY` and `JWT_PUBLIC_KEY`.

Claims:

- `sub`
- `email`
- `iss`
- `iat`
- `exp`

`exp` is one hour after issue time.

## Remote Hash Requirements

The value at `password_hash_url` must:

- be reachable by the Rails app
- return HTTP 200
- return only the plaintext Argon2 hash in the response body

If the URL is unreachable, invalid, or returns non-Argon2 content, registration and login fail.

## Host Authorization

If you expose the app on a custom hostname in development or production, Rails may block it with:

```text
Blocked hosts: your-hostname
```

Allow the hostname in the relevant environment file, for example:

```ruby
config.hosts << "your-app.example.com"
```

Or allow a subdomain pattern:

```ruby
config.hosts << /.*\.example\.com/
```

Restart the server after changing host authorization.

## Running Tests

Run the test suite with:

```bash
JWT_ISSUER=bad-passwords-test bin/rails test
```

## Notes

- JSON requests are exempt from CSRF verification.
- HTML form submissions still use standard Rails CSRF protection.
- The app stores only `email` and `password_hash_url`.
- The app does not store plaintext passwords or local password digests.
- Unknown email and wrong password return the same login error message to reduce account enumeration risk.
