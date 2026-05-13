#!/bin/sh
set -e

echo "Entrypoint: running database migrations..."
mix ecto.migrate

if [ "${MIX_ENV}" != "prod" ]; then
  if [ -f priv/repo/seeds.exs ]; then
    echo "Entrypoint: running seed script (non-prod)..."
    mix run priv/repo/seeds.exs
  else
    echo "Entrypoint: no seed script found, skipping."
  fi
else
  echo "Entrypoint: MIX_ENV=prod — skipping seeds."
fi

echo "Entrypoint: executing command: $@"
exec "$@"
