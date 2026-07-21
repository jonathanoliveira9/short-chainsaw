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

The app will be available at [http://localhost](http://localhost).

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
