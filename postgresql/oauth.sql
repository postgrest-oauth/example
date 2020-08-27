CREATE EXTENSION pgcrypto;

CREATE SCHEMA IF NOT EXISTS oauth2;

CREATE OR REPLACE FUNCTION oauth2.create_owner(email text, phone text, password text, language text, verification_code text, verification_route text, OUT id varchar)
AS $$
        INSERT INTO api.users(email, phone, password, language) VALUES (NULLIF(email, ''), NULLIF(phone, ''), crypt(password, gen_salt('bf')), NULLIF(language, '')) RETURNING id::varchar;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.create_facebook_owner(obj json, phone varchar, OUT id varchar, OUT role varchar, OUT jti varchar)
AS $$
        INSERT INTO api.users(email, phone, role, facebook_id)
        VALUES
         (
         obj->>'email'::varchar,
         phone,
         'verified',
         obj->>'id'::varchar
         )
        RETURNING id::varchar, role::varchar, jti::varchar;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.re_verify(username text, verification_code text, verification_route text, OUT id varchar)
AS $$
        SELECT id::varchar FROM api.users WHERE role = 'unverified' AND (email = username OR phone = username) LIMIT 1;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.check_owner(username text, password text, OUT id varchar, OUT role varchar, OUT jti varchar)
AS $$
SELECT id::varchar, role::varchar, jti::varchar FROM api.users
    WHERE (email = check_owner.username OR phone = check_owner.username)
        AND users.password = crypt(check_owner.password, users.password);
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.check_owner_facebook(facebook_id varchar, OUT id varchar, OUT role varchar, OUT jti varchar)
AS $$
SELECT id::varchar, role::varchar, jti::varchar FROM api.users
    WHERE facebook_id = check_owner_facebook.facebook_id;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.owner_role_and_jti_by_id(id text, OUT role varchar, OUT jti varchar)
AS $$
SELECT role::varchar, jti::varchar FROM api.users
    WHERE (id = owner_role_and_jti_by_id.id::bigint);
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.verify_owner(user_id varchar) RETURNS void
AS $$
UPDATE api.users SET role='verified' WHERE api.users.id = user_id::int;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.password_request(username text, verification_code text, verification_route text, OUT id varchar)
AS $$
        SELECT id::varchar from api.users WHERE email = password_request.username OR phone = password_request.username;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.password_reset(id text, password text) RETURNS void
AS $$
        UPDATE api.users SET password = crypt(password_reset.password, gen_salt('bf')), jti = now() WHERE id = password_reset.id::int;
$$ LANGUAGE SQL;


CREATE TABLE IF NOT EXISTS
    oauth2.clients (
      id                  text NOT NULL PRIMARY KEY,
      secret              text DEFAULT gen_random_uuid()::text,
      redirect_uri        text DEFAULT NULL UNIQUE,
      type                varchar NOT NULL DEFAULT 'public'
    );


INSERT INTO oauth2.clients(id, redirect_uri, type) VALUES('mobile', 'https://mobile.uri', 'public');
INSERT INTO oauth2.clients(id, redirect_uri, type) VALUES('spa', 'https://spa.uri', 'public');
INSERT INTO oauth2.clients(id, secret, type) VALUES('worker', 'secret', 'confidential');


CREATE OR REPLACE FUNCTION oauth2.check_client(client_id text, OUT redirect_uri text)
AS $$
SELECT redirect_uri FROM oauth2.clients
    WHERE id = check_client.client_id;
$$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION oauth2.check_client_secret(client_id text, client_secret text, OUT type varchar)
AS $$
SELECT type FROM oauth2.clients
    WHERE id = check_client_secret.client_id AND secret = check_client_secret.client_secret;
$$ LANGUAGE SQL;


CREATE ROLE "msrv-worker" NOLOGIN;
GRANT "msrv-worker" TO "authenticator";
GRANT USAGE ON SCHEMA oauth2 TO "msrv-worker";
GRANT SELECT ON TABLE oauth2.clients TO "msrv-worker";