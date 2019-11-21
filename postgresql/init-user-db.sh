#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" <<-EOSQL

CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD '$PGRST_AUTHENTICATOR_PASSWORD';

CREATE ROLE "guest" NOLOGIN;
GRANT "guest" TO "authenticator";

EOSQL

for file in /api.sql; do
    psql -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    -f "$file"
done

for file in /oauth.sql; do
    psql -v ON_ERROR_STOP=1 \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    -f "$file"
done