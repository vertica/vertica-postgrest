vsql -c "
create table public.pg_db_role_setting (
  setdatabase integer,
  setrole integer,
  setconfig ARRAY[varchar]
);
create table public.pg_database (
  oid integer,
  datname varchar,
  datdba integer,
  encoding integer,
  datlocprovider char,
  datistemplate boolean,
  datallowconn boolean,
  datconnlimit integer,
  datfrozenxid integer,
  datminmxid integer,
  dattablespace integer,
  datcollate varchar,
  datctype varchar,
  daticulocale varchar,
  datcollversion varchar,
  datacl ARRAY[varchar]
);

select set_vertica_options('Basic', 'DISABLE_DEPARSE_CHECK');
create schema api;
create table api.todos (
  id identity primary key,
  done boolean not null default false,
  task varchar not null,
  due timestamptz
);
insert into api.todos (task) values ('finish tutorial 0');
insert into api.todos (task) values ('pat self on back');
create role web_anon;
grant usage on schema api to web_anon;
grant select on api.todos to web_anon;
CREATE USER authenticator IDENTIFIED BY 'mysecretpassword';
grant web_anon to authenticator;
GRANT SELECT ON ALL TABLES IN SCHEMA public to authenticator;
"
