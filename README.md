# Short Chainsaw

This is a project to apply system design about short link.

## Requirements

* Ruby 3.4.10
* PostgreSQL
* Docker and Docker Compose (for the containerized setup)

## Running the server

### With Docker Compose (recommended)

```sh
RAILS_MASTER_KEY=$(cat config/master.key) docker compose up --build
```

The app will be available at [http://localhost:3000](http://localhost:3000).

To run it in the background:

```sh
RAILS_MASTER_KEY=$(cat config/master.key) docker compose up --build -d
```

Stop it with:

```sh
docker compose down
```

### Locally

1. Install dependencies:

   ```sh
   bundle install
   ```

2. Configure the database connection (defaults to `localhost:5432` with user/password `postgres`, see `config/database.yml`).

3. Create and set up the database:

   ```sh
   bin/rails db:prepare
   ```

4. Start the server:

   ```sh
   bin/rails server
   ```

The app will be available at [http://localhost:3000](http://localhost:3000).

## Authentication

Authentication is handled by Devise + [devise-jwt](https://github.com/waiting-for-dev/devise-jwt). A user has an `email` and a `password`.

### Create a user

```sh
curl --location 'http://localhost:3000/sign_up' \
--header 'Content-Type: application/json' \
--data-raw '{"user":{"email":"admin@gmail.com","password":"supersecret","password_confirmation":"supersecret"}}'
```

The response contains the JWT in the `Authorization` response header (`Bearer <token>`).

### Log in

```sh
curl --location 'http://localhost:3000/login' \
--header 'Content-Type: application/json' \
--data-raw '{"user":{"email":"admin@gmail.com","password":"supersecret"}}'
```

### Call a protected endpoint

Pass the token from the `Authorization` header above on subsequent requests:

```sh
curl --location 'http://localhost:3000/me' \
--header 'Authorization: Bearer <token>'
```

### Log out

```sh
curl --location --request DELETE 'http://localhost:3000/logout' \
--header 'Authorization: Bearer <token>'
```

## Links

Endpoints for creating and resolving short links. `generate`, `update` and `destroy` require the `Authorization: Bearer <token>` header (see [Authentication](#authentication)); `show` (the redirect) is public. A link can only be updated or destroyed by the user who created it.

### Generate a short link

```sh
curl --location 'http://localhost:3000/links/generate' \
--header 'Authorization: Bearer <token>' \
--header 'Content-Type: application/json' \
--data-raw '{"link":"https://example.com/some/very/long/path"}'
```

Returns `201 Created`:

```json
{ "short_link": "<code>", "expires_at": "<datetime>" }
```

### Resolve (redirect) a short link

```sh
curl --location 'http://localhost:3000/links/<short_link>'
```

Returns `302 Found` with a `Location` header pointing at the original link. A missing, inactive or expired short link returns `404 Not Found`.

### Update a short link's destination

```sh
curl --location --request PATCH 'http://localhost:3000/links/<short_link>' \
--header 'Authorization: Bearer <token>' \
--header 'Content-Type: application/json' \
--data-raw '{"link":"https://example.com/new/destination"}'
```

Returns `200 OK`.

### Delete a short link

```sh
curl --location --request DELETE 'http://localhost:3000/links/<short_link>' \
--header 'Authorization: Bearer <token>'
```

Returns `204 No Content`.
