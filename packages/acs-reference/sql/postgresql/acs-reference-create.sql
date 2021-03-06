-- packages/acs-reference/sql/postgresql/acs-reference-create.sql
--
-- @author jon@jongriffin.com
-- @creation-date 2001-07-16
--
-- @cvs-id $Id$

-- setup the basic admin privileges

select acs_privilege__create_privilege('acs_reference_create');
select acs_privilege__create_privilege('acs_reference_write');
select acs_privilege__create_privilege('acs_reference_read');
select acs_privilege__create_privilege('acs_reference_delete');
    
select acs_privilege__add_child('create','acs_reference_create');
select acs_privilege__add_child('write', 'acs_reference_write');
select acs_privilege__add_child('read',  'acs_reference_read');
select acs_privilege__add_child('delete','acs_reference_delete');

-- Create the basic object type used to represent a reference database
select acs_object_type__create_type (
        'acs_reference_repository',
        'ACS Reference Repository',
        'ACS Reference Repositories', 
        'acs_object',
        'acs_reference_repositories',
        'repository_id',
        null,
        'f',
	null,
	'acs_object__default_name'
);

-- A table to store metadata for each reference database
-- add functions to do exports and imports to selected tables.

create table acs_reference_repositories (
    repository_id	integer
			constraint arr_repository_id_fk references acs_objects (object_id)
			constraint arr_repository_id_pk primary key,
    -- what is the table name we are monitoring
    table_name		varchar(100)  
			constraint arr_table_name_nn not null
			constraint arr_table_name_un unique,
    -- is this external or internal data
    internal_data_p     boolean,
    -- Does this source include pl/sql package?
    package_name	varchar(100)
			constraint arr_package_name_un unique,
    -- last updated
    last_update		timestamptz,
    -- where is this data from
    source		varchar(1000),
    source_url		varchar(255),
    -- should default to today
    effective_date	timestamptz, -- default sysdate
    expiry_date		timestamptz,
    -- a text field to hold the maintainer
    maintainer_id	integer
			constraint arr_maintainer_id_fk references persons(person_id),
    -- this could be ancillary docs, pdf's etc
    -- needs to be fixed for PG
    -- DRB: needs to use Content Repository for both PG and Oracle, no???
    lob 		integer
);

-- API


-- default for Oracle



-- added
select define_function_args('acs_reference__new','repository_id;null,table_name,internal_data_p;"f",package_name;null,last_update;sysdate,source;null,source_url;null,effective_date;sysdate,expiry_date;null,maintainer_id;null,notes;null (not Oracle empty_blob()),first_names;null,last_name;null,creation_ip;null,object_type;"acs_reference_repository",creation_user;null');

--
-- procedure acs_reference__new/16
--
CREATE OR REPLACE FUNCTION acs_reference__new(
   p_repository_id integer,      -- default null
   p_table_name varchar, 
   p_internal_data_p boolean,    -- default "f"
   p_package_name varchar,       -- default null
   p_last_update timestamptz,    -- default sysdate
   p_source varchar,             -- default null
   p_source_url varchar,         -- default null
   p_effective_date timestamptz, -- default sysdate
   p_expiry_date timestamptz,    -- default null
   p_maintainer_id integer,      -- default null
   p_notes integer,              -- default null (not Oracle empty_blob())
   p_first_names varchar,        -- default null
   p_last_name varchar,          -- default null
   p_creation_ip varchar,        -- default null
   p_object_type varchar,        -- default "acs_reference_repository"
   p_creation_user integer       -- default null

) RETURNS integer AS $$
DECLARE
    v_repository_id acs_reference_repositories.repository_id%TYPE;
    v_object_type   acs_objects.object_type%TYPE;
    v_maintainer_id persons.person_id%TYPE;
BEGIN
    if p_object_type is null then
        v_object_type := 'acs_reference_repository';
    else
        v_object_type := p_object_type;
    end if;

    v_repository_id := acs_object__new (
         p_repository_id,    
         v_object_type,
         now(),
         p_creation_user,
         p_creation_ip,
         null,
         't',
         p_source,
         null
    );

    -- This logic is not correct as the maintainer could already exist
    -- The way around this is a little clunky as you can search persons
    -- then pick an existing person or add a new one, to many screens!
    -- I really doubt the need for person anyway.
    --
    -- It probably needs to just be a UI function and pass
    -- in the value for maintainer.
    --
    -- IN OTHER WORDS
    -- Guaranteed to probably break in the future if you depend on
    -- first_names and last_name to still exist as a param
    -- This needs to be updated in the Oracle version also
    -- NEEDS TO BE FIXED - jag

    if p_first_names is not null and p_last_name is not null and p_maintainer_id is null then
        v_maintainer_id := person__new (null, 'person', now(), null, null, null, null,
	                                p_first_names, p_last_name, null);
	else if p_maintainer_id is not null then
           v_maintainer_id := p_maintainer_id;
        else 
	    v_maintainer_id := null;
	end if;
    end if;

    insert into acs_reference_repositories
        (repository_id,table_name,internal_data_p,
         last_update,package_name,source, 
         source_url,effective_date,expiry_date,
         maintainer_id,lob)
    values 
        (v_repository_id, p_table_name, p_internal_data_p,
         p_last_update, p_package_name, p_source, p_source_url,
         p_effective_date, p_expiry_date, v_maintainer_id, p_notes);

    return v_repository_id;    
END;

$$ LANGUAGE plpgsql;

-- made initially for PG 


--
-- procedure acs_reference__new/5
--
CREATE OR REPLACE FUNCTION acs_reference__new(
   p_table_name varchar, 
   p_last_update timestamptz,   -- default sysdate
   p_source varchar,            -- default null
   p_source_url varchar,        -- default null
   p_effective_date timestamptz -- default sysdate

) RETURNS integer AS $$
DECLARE
    v_repository_id acs_reference_repositories.repository_id%TYPE;
BEGIN
    return acs_reference__new(null, p_table_name, 'f', null, null, p_source, p_source_url,
                              p_effective_date, null, null, null, null, null, null,
                              'acs_reference_repository', null);
END;

$$ LANGUAGE plpgsql;




-- added
select define_function_args('acs_reference__delete','repository_id');

--
-- procedure acs_reference__delete/1
--
CREATE OR REPLACE FUNCTION acs_reference__delete(
   p_repository_id integer
) RETURNS integer AS $$
DECLARE
    v_maintainer_id		acs_objects.object_id%TYPE;
BEGIN
    select maintainer_id into v_maintainer_id
    from   acs_reference_repositories
    where  repository_id = p_repository_id;

    delete from acs_reference_repositories
    where repository_id = p_repository_id;

    perform acs_object__delete(p_repository_id);
    return 0;
END;

$$ LANGUAGE plpgsql;



-- added
select define_function_args('acs_reference__is_expired_p','repository_id');

--
-- procedure acs_reference__is_expired_p/1
--
CREATE OR REPLACE FUNCTION acs_reference__is_expired_p(
   repository_id integer
) RETURNS char AS $$
DECLARE
    v_expiry_date acs_reference_repositories.expiry_date%TYPE;
BEGIN
    select expiry_date into v_expiry_date
    from   acs_reference_repositories
    where  repository_id = is_expired_p.repository_id;

    if coalesce(v_expiry_date,now()+1) < now() then
        return 't';
    else
        return 'f';
    end if;
END;

$$ LANGUAGE plpgsql;

