CREATE SCHEMA IF NOT EXISTS api;

CREATE TABLE IF NOT EXISTS
    api.users (
      id                  serial PRIMARY KEY NOT NULL,
      facebook_id         varchar DEFAULT NULL,
      email               text DEFAULT NULL UNIQUE CHECK ( email ~* '^.+@.+\..+$' ),
      phone               text DEFAULT NULL UNIQUE,
      password            text NOT NULL DEFAULT md5(random()::text) CHECK (length(password) < 512),
      role                varchar NOT NULL DEFAULT 'unverified',
      language            varchar DEFAULT NULL,
      jti                 timestamp without time zone NOT NULL DEFAULT now()
      CHECK(email IS NOT NULL OR phone IS NOT NULL)
    );

CREATE ROLE "unverified" NOLOGIN;
GRANT "unverified" TO "authenticator";
GRANT USAGE ON SCHEMA api TO "unverified";
GRANT SELECT ON TABLE api.users TO "unverified";