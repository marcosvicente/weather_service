# Weather Service

A Rails application that imports weather forecasts from ZIP archives. Upload a `.zip` file containing weather JSON files; Active Storage saves the upload and Sidekiq processes it asynchronously. Forecast values and the imported JSON documents are saved in PostgreSQL.

## Requirements

- Docker with Docker Compose
- Visual Studio Code with the Dev Containers extension

The Dev Container provides Ruby, PostgreSQL, Redis, and the Rails dependencies.

## Development setup

1. Open this repository in Visual Studio Code and run **Dev Containers: Reopen in Container**.
2. Start the Sidekiq worker from a terminal in the container:

   ```sh
   docker compose -f .devcontainer/compose.yaml up -d jobs
   ```

3. Start the Rails server:

   ```sh
   bin/rails server -b 0.0.0.0
   ```

4. Open [http://localhost:3000](http://localhost:3000).

The Dev Container setup installs gems and npm packages, builds the CSS, and prepares the development and test databases. PostgreSQL and Redis are Compose dependencies. The `jobs` service runs Sidekiq and must be started to process uploaded archives.

## Upload format

Upload a ZIP archive up to 10 MB. It may contain up to 20 `.json` files, each no larger than 5 MB, with a combined uncompressed size no larger than 10 MB. Nested directories are supported. Each JSON file must contain a JSON object.

At least one JSON file must contain a forecast in the Open-Meteo response shape, including:

- `current.temperature_2m`
- `daily.temperature_2m_max` (a non-empty array)
- `daily.temperature_2m_min` (a non-empty array)
- `zip_code` or `postal_code`

An optional `address` value is displayed with the forecast. See [`spec/fixtures/weather_forecast.json`](spec/fixtures/weather_forecast.json) for an example. All JSON objects in the ZIP are stored in the forecast record; the first valid forecast object supplies the displayed ZIP code, address, and temperatures.

The upload page displays the archive's processing status. Invalid or unreadable archives are marked as failed and show an error message.

## Tests

Run the RSpec suite inside the Dev Container:

```sh
RAILS_ENV=test bundle exec rspec
```

Run the Ruby linter:

```sh
bundle exec rubocop
```
