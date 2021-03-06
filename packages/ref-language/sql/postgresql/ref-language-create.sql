-- packages/ref-language/sql/postgresql/language.sql
--
-- @author jon@jongriffin.com
-- @creation-date 2000-11-21
-- @cvs-id $Id$
--


-- ISO 639
create table language_codes (
    language_id char(2)
        constraint language_codes_language_id_pk
        primary key,
    name varchar(100)
        constraint language_codes_name_nn
        not null
);

comment on table language_codes is '
    This is data from the ISO 639-1 standard on language codes.
';

comment on column language_codes.language_id is '
    This is the ISO standard language 2 chars code
';

comment on column language_codes.name is '
    This is the English version of the language name. 
';

-- now register this table with the repository
select acs_reference__new(
    'LANGUAGE_CODES',
    null,
    'ISO 639-1',
    'http://www.iso.ch',
    now()
);

-- Languages ISO-639-2 codes

create table language_639_2_codes (
       iso_639_2            char(3) constraint language_codes_iso_639_2_pk primary key,
       iso_639_1            char(2),
       label                varchar(200)
);

comment on table language_639_2_codes is 'Contains ISO-639-2 language codes and their corresponding ISO-639-1 when it exists.';
