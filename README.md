# Bad Passwords

Rails application for delegated password verification against a remotely hosted plaintext Argon2 hash.

## What It Does

- `POST /register` stores an `email` and `password_hash_url` after proving the submitted plaintext password matches the remote Argon2 hash.
- `POST /login` fetches the current hash from the stored URL, verifies the password, and returns an RS256-signed JWT.
- `POST /validate` verifies a JWT with the configured RSA public key and expected issuer, then returns the decoded payload.
- `DELETE /logout` rotates the user's token version using either valid credentials or a valid token, invalidating all previously issued tokens.
- `/` provides an HTML interface with registration, login, and navigation to token validation and API docs.
- `/example.txt` returns a cached plaintext Argon2 hash for `test123`.

## Run It

```bash
bundle install
bin/rails db:prepare
ruby script/generate_jwt_keypair
```

Set these env vars:

```bash
export JWT_ISSUER=bad-passwords-dev
export JWT_PRIVATE_KEY="$(cat path/to/jwt_private.pem)"
export JWT_PUBLIC_KEY="$(cat path/to/jwt_public.pem)"
```

`JWT_ISSUER` is optional for local development. If omitted, the app uses `bad-passwords-local`.
`JWT_PRIVATE_KEY` and `JWT_PUBLIC_KEY` are optional in development and test because those environments configure a fixed local keypair. Set them explicitly in production.
`JWT_ISSUER` is also configured in development and test, and only needs to be set explicitly outside those environments.

Then start the server:

```bash
bin/rails server
```

Open [http://127.0.0.1:3000](http://127.0.0.1:3000).

## JSON API

Send `Content-Type: application/json` and `Accept: application/json`.

Register:

```bash
curl -i http://127.0.0.1:3000/register \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{
    "email": "user@example.com",
    "password_hash_url": "http://127.0.0.1:3000/example.txt",
    "password": "test123"
  }'
```

Login:

```bash
curl -i http://127.0.0.1:3000/login \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{
    "email": "user@example.com",
    "password": "test123"
  }'
```

Validate:

```bash
curl -i http://127.0.0.1:3000/validate \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{
    "token": "JWT_TOKEN_HERE"
  }'
```

Successful login returns JSON with:

- `token`
- `token_type`
- `email`

The JWT contains:

- `sub`
- `iss`
- `ver`
- `iat`
- `exp`

Failed login returns:

```json
{ "error": "Invalid email or password." }
```

Remote hash verification failures return:

```json
{ "error": "Could not verify the password hash URL." }
```

Successful token validation returns:

```json
{
  "valid": true,
  "payload": {
    "sub": "user@example.com",
    "iss": "bad-passwords-dev",
    "iat": 1710000000,
    "exp": 1710003600
  }
}
```

Failed token validation returns:

```json
{ "valid": false, "error": "Invalid token." }
```

Validation rejects tokens with the wrong signature, issuer, expiration, or token version.

Logout with credentials:

```bash
curl -i http://127.0.0.1:3000/logout \
  -X DELETE \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{
    "username": "user@example.com",
    "password": "test123"
  }'
```

Logout with a token:

```bash
curl -i http://127.0.0.1:3000/logout \
  -X DELETE \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer JWT_TOKEN_HERE'
```

Successful logout returns:

```json
{ "success": true, "email": "user@example.com" }
```

Failed logout returns:

```json
{ "error": "Invalid token or credentials." }
```

## Notes

- The remote hash URL must return only a plaintext Argon2 hash with HTTP 200.
- Requests are rate-limited per IP and return `429 Too Many Requests` when exceeded.
- JSON requests skip CSRF protection. HTML form submissions still use normal Rails CSRF protection.
- The app stores only `email` and `password_hash_url`.
- If Rails blocks your hostname, add it to the relevant `config.hosts` allowlist.

## Test

```bash
JWT_ISSUER=bad-passwords-test bin/rails test
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
