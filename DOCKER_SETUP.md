# Docker Setup

This repo is a Flutter app. It expects a separate PHP backend named `alumni_php`.

## What this stack runs

- `frontend`: Flutter web build served by Nginx
- `backend`: Apache + PHP 8.2 serving your existing `alumni_php` folder
- `db`: MySQL 8.0 database named `alumni_tracer`
- `redis`: optional cache/session store for the PHP layer in deployment setups

## Compose files

- `docker-compose.yml`: simple local dev stack
- `docker-compose.deploy.yml`: deployment-style stack with reverse-proxy `nginx`, `redis`, named `volumes`, and explicit `container_name` / `image` usage

## Important assumption

Your PHP backend is **not inside this repo**. The compose file mounts it from:

```text
../alumni_php
```

If your backend lives somewhere else, set `ALUMNI_PHP_PATH` before starting.

PowerShell example:

```powershell
$env:ALUMNI_PHP_PATH = "C:\xampp\htdocs\alumni_php"
docker compose up --build
```

If your PHP code is next to this repo in a sibling folder named `alumni_php`, you can simply run:

```powershell
docker compose up --build
```

## Deployment Compose

This compose file adds:

- `nginx` as the public entrypoint on port `80`
- `frontend` as a built Docker image
- `backend` as the PHP container
- `redis` for cache/session support
- named `volumes` for MySQL and Redis persistence

Run it with:

```powershell
$env:ALUMNI_PHP_PATH = "C:\xampp\htdocs\alumni_php"
docker compose -f docker-compose.deploy.yml up --build
```

The public app URL will then be:

```text
http://localhost/
```

And API requests will go through:

```text
http://localhost/alumni_php
```

## URLs

- Flutter web app: `http://localhost:8081`
- PHP backend: `http://localhost:8080/alumni_php`
- MySQL: `localhost:3306`
- Deployment stack public URL: `http://localhost`

## Why the app works with this

The Flutter web build is compiled with:

```text
API_BASE_URL=http://localhost:8080/alumni_php
```

That matches the backend container published on port `8080`.

## First-time notes

- The MySQL container only imports the SQL files that already exist in this repo:
  - `create_users_table.sql`
  - `create_jobs_tables.sql`
- If `alumni_php` needs more tables, add more `.sql` files and mount them into `/docker-entrypoint-initdb.d/`.
- Your PHP code must be configured to connect to:
  - host: `db`
  - database: `alumni_tracer`
  - user: `alumni_user`
  - password: `alumni_pass`
- If you want Redis-backed PHP sessions or caching, your PHP code should use:
  - host: `redis`
  - port: `6379`

## Common commands

Start:

```powershell
docker compose up --build
```

Start deployment stack:

```powershell
docker compose -f docker-compose.deploy.yml up --build
```

Stop:

```powershell
docker compose down
```

Stop and remove database volume:

```powershell
docker compose down -v
```
