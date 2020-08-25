FROM postgres:12.1-alpine
COPY ./api.sql ./
COPY ./oauth.sql ./
COPY ./init-user-db.sh /docker-entrypoint-initdb.d/
