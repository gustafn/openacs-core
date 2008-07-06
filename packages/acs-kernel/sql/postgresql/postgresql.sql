create view dual as select now() as sysdate;

-- used to support anonymous plsql blocks in the db_plsql function call in tcl.
create sequence t_anon_func_seq;
create view anon_func_seq as 
select nextval('t_anon_func_seq') as nextval;

create or replace function instr(varchar,char,integer,integer) returns integer as '
declare
        str             alias for $1;
        pat             alias for $2;
        dir             alias for $3;
        cnt             alias for $4;
        v_len           integer;
        v_i             integer;
        v_c             char;
        v_cnt           integer;
        v_inc           integer;
begin
        v_len := length(str);
        v_cnt := 0;
        
        if dir < 0 then
           v_inc := \-1;
           v_i   := v_len;
        else 
           v_inc := 1;
           v_i   := 1;
        end if;
           
        while v_i > 0 and v_i <= v_len LOOP
          v_c := substr(str,v_i,1);
          if v_c::char = pat::char then 
            v_cnt := v_cnt + 1;
            if v_cnt = cnt then 
              return v_i;
            end if;
          end if;
          v_i := v_i + v_inc;
        end loop;

        return 0;

end;' language 'plpgsql' immutable;


create or replace function instr(varchar,char,integer) returns integer as '
declare
        str             alias for $1;
        pat             alias for $2;
        dir             alias for $3;
begin
        return instr(str,pat,dir,1);
end;' language 'plpgsql' immutable;


create or replace function instr(varchar,char) returns integer as '
declare
        str             alias for $1;
        pat             alias for $2;
begin
        return instr(str,pat,1,1);
end;' language 'plpgsql' immutable;


-- Splits string on requested character. Returns requested element
-- (1-based)

create or replace function split(varchar,char,integer)
returns varchar as '
declare
  p_string		alias for $1;
  p_split_char		alias for $2;
  p_element		alias for $3;

  v_left_split		integer;
  v_right_split		integer;
  v_len			integer;
begin
  v_len = length(p_string);
  if v_len = 0 or p_string is null or p_element <= 0 then
    return NULL;
  end if;
  if p_element = 1 then
    v_left_split := 0;
  else
    v_left_split := instr(p_string, p_split_char, 1, p_element-1);
  end if;
  v_right_split := instr(p_string, p_split_char, 1, p_element);
  if v_right_split = 0 then
    v_right_split = v_len + 1;
  end if;
  if v_left_split = 0 and v_right_split = v_len+1 and p_element <> 1 then
    return null;
  end if;
  return substr(p_string, v_left_split+1, (v_right_split - v_left_split - 1));
end;' language 'plpgsql' immutable;


create or replace function get_func_drop_command (varchar) returns varchar as '
declare
        fname           alias for $1;
        nargs           integer default 0;
        v_pos           integer;
        v_funcdef       text;
        v_args          varchar;
        v_one_arg       varchar;
        v_one_type      varchar;
        v_nargs         integer;
begin
        v_funcdef := ''drop function '' || fname || ''('';

        select proargtypes, pronargs
          into v_args, v_nargs
          from pg_proc 
         where proname = fname::name;

        v_pos := position('' '' in v_args);
        
        while nargs < v_nargs loop
              nargs := nargs + 1;
              if nargs = v_nargs then 
                 v_one_arg := v_args;
                 v_args    := '''';
              else
                 v_one_arg := substr(v_args, 1, v_pos \- 1);
                 v_args    := substr(v_args, v_pos + 1);
                 v_pos     := position('' '' in v_args);            
              end if;
              select case when nargs = 1 
                            then typname 
                            else '','' || typname 
                          end into v_one_type 
                from pg_type 
               where oid = v_one_arg::integer;
              v_funcdef := v_funcdef || v_one_type;            
        end loop;
        v_funcdef := v_funcdef || '')'';

        return v_funcdef;

end;' language 'plpgsql';

create or replace function drop_package (varchar) returns varchar as '
declare
       package_name      alias for $1;
       v_rec             record;
       v_drop_cmd        varchar;
       v_pkg_name        varchar;
begin
        raise NOTICE ''DROP PACKAGE: %'', package_name;
        v_pkg_name := package_name || ''\\\\_\\\\_'' || ''%'';

        for v_rec in select proname 
                       from pg_proc 
                      where proname like v_pkg_name 
                   order by proname 
        LOOP
            raise NOTICE ''DROPPING FUNCTION: %'', v_rec.proname;
            v_drop_cmd := get_func_drop_command (v_rec.proname::varchar);
            EXECUTE v_drop_cmd;
        end loop;

        if NOT FOUND then 
          raise NOTICE ''PACKAGE: % NOT FOUND'', package_name;
        else
          raise NOTICE ''PACKAGE: %: DROPPED'', package_name;
        end if;
        
        return null;

end;' language 'plpgsql';

create or replace function number_src(text) returns text as '
declare
        v_src   alias for $1;
        v_pos   integer;
        v_ret   text default '''';
        v_tmp   text;
        v_cnt   integer default -1;
begin
        if v_src is null then 
	     return null;
        end if;

        v_tmp := v_src;
        LOOP
            v_pos := position(''\n'' in v_tmp);
            v_cnt := v_cnt + 1;

            exit when v_pos = 0;

            if v_cnt != 0 then
              v_ret := v_ret || rpad(v_cnt,10) || substr(v_tmp,1,v_pos);
            end if;
            v_tmp := substr(v_tmp,v_pos + 1);
        end LOOP;

        return v_ret || rpad(v_cnt,10) || v_tmp;

end;' language 'plpgsql' immutable strict;

create or replace function get_func_definition (varchar,oidvector) returns text as '
declare
        fname           alias for $1;
        args            alias for $2;
        nargs           integer default 0;
        v_pos           integer;
        v_funcdef       text default '''';
        v_args          varchar;
        v_one_arg       varchar;
        v_one_type      varchar;
        v_nargs         integer;
        v_src           text;
        v_rettype       varchar;
begin
        select proargtypes, pronargs, number_src(prosrc), 
               (select typname from pg_type where oid = p.prorettype)
          into v_args, v_nargs, v_src, v_rettype
          from pg_proc p 
         where proname = fname::name
           and proargtypes = args;

         v_funcdef := v_funcdef || ''
create or replace function '' || fname || ''('';

         v_pos := position('' '' in v_args);

         while nargs < v_nargs loop
             nargs := nargs + 1;
             if nargs = v_nargs then 
                 v_one_arg := v_args;
                 v_args    := '''';
             else
                 v_one_arg := substr(v_args, 1, v_pos \- 1);
                 v_args    := substr(v_args, v_pos + 1);
                 v_pos     := position('' '' in v_args);            
             end if;
             select case when nargs = 1 
                           then typname 
                           else '','' || typname 
                         end into v_one_type 
               from pg_type 
              where oid = v_one_arg;
             v_funcdef := v_funcdef || v_one_type;
         end loop;
         v_funcdef := v_funcdef || '') returns '' || v_rettype || '' as \\\'\\n'' || v_src || ''\\\' language \\\'plpgsql\\\';'';

        return v_funcdef;

end;' language 'plpgsql' stable strict;

create or replace function get_func_header(varchar,oidvector) returns text as '
declare
        fname   alias for $1;
        args    alias for $2;
        v_src   text;
        pos     integer;
begin
        v_src := get_func_definition(fname,args);
        pos := position(''begin'' in lower(v_src));

        return substr(v_src, 1, pos + 4);

end;' language 'plpgsql' stable strict;

create view acs_func_defs as 
select get_func_definition(proname::varchar,proargtypes) as definition, 
       proname as fname 
  from pg_proc;

create view acs_func_headers as 
select get_func_header(proname::varchar,proargtypes) as definition, 
       proname as fname 
  from pg_proc;

----------------------------------------------------------------------------

create or replace function inline_0 () returns integer as '
-- Create a bitfromint4(integer) function if it doesn''t exists.
-- This function is no longer present in 7.3 and above
declare
    v_bitfromint4_count integer;
begin
    select into v_bitfromint4_count count(*) from pg_proc where proname = ''bitfromint4'';
    if v_bitfromint4_count = 0 then
	create or replace function bitfromint4 (integer) returns bit varying as ''
	begin 
    	    return $1::bit(32);
	end;'' language ''plpgsql'' immutable strict;
   end if;
   return 1;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();

create or replace function inline_1 () returns integer as '
-- Create a bitfromint4(integer) function if it doesn''t exists.
-- This function is no longer present in 7.3 and above
declare
    v_bittoint4_count integer;
begin
    select into v_bittoint4_count count(*) from pg_proc where proname = ''bittoint4'';
    if v_bittoint4_count = 0 then
	create or replace function bittoint4 (bit varying) returns integer as ''
	begin 
    	    return "int4"($1);
	end;'' language ''plpgsql'' immutable strict;
   end if;
   return 1;
end;' language 'plpgsql';

select inline_1();
drop function inline_1();


-- tree query support, m-vgID method.

-- DRB: I've replaced the old, text-based tree sort keys with a 
-- more compact version based on bit strings.  PostgreSQL now 
-- offers excellent support for arbitrary strings of bits, and
-- does a good job of optimizing manipulations on these strings
-- that fall on byte boundaries.  They're also fully supported 
-- by the PG's default high-concurrency nbtree index type.

-- Benefits of this new approach over the old, text-based
-- approach:

-- 1. Breaks dependency on the text type's collation order.  This
--    will be greatly appreciated by those who want to use OpenACS 4
--    with full locale support, including the proper collation order.

-- 2. Storage is one byte per level for each level in the tree that
--    has fewer than 128 nodes.  If more nodes exist at a given level
--    two bytes are required.  The old scheme used three bytes per
--    level.  Along with saving space in data tables, this will speed
--    key comparisons during index scans and increases the number of
--    keys stored in any given index page.

-- 3. 2^31 nodes per level are allowed in a given subtree, rather
--    than the 25K or so supported in the text-based scheme (though
--    in reality the old scheme supported more than enough nodes
--    per level)

-- PostgreSQL note: the PL/pgSQL parser doesn't seem to like the
-- SQL92 standard "bit varying" so I've used the synonym "varbit"
-- throughout.

create or replace function int_to_tree_key(integer) returns varbit as '

-- Convert an integer into the bit string format used to store
-- tree sort keys.   Using 4 bytes for the long keys requires
-- using -2^31 rather than 2^31 to avoid a twos-complement 
-- "integer out of range" error in PG - if for some reason you
-- want to use a smaller value use positive powers of two!

-- There was an "out of range" check in here when I was using 15
-- bit long keys but the only check that does anything with the long
-- keys is to check for negative numbers.

declare
  p_intkey        alias for $1;
begin
  if p_intkey < 0 then
    raise exception ''int_to_tree_key: key must be a positive integer'';
  end if;

  if p_intkey < 128 then
    return substring(bitfromint4(p_intkey), 25, 8);
  else
    return substring(bitfromint4(cast (-2^31 + p_intkey as int4)), 1, 32);
  end if;

end;' language 'plpgsql' immutable strict;

create or replace function tree_key_to_int(varbit, integer) returns integer as '

-- Convert the compressed key for the node at the given level to an 
-- integer.

declare
  p_tree_key      alias for $1;
  p_level         alias for $2;
  v_level         integer default 0;
  v_parent_pos    integer default 1;
  v_pos           integer default 1;
begin

  -- Find the right key first
  while v_pos < length(p_tree_key) and v_level < p_level loop
    v_parent_pos := v_pos;
    v_level := v_level + 1;
    if substring(p_tree_key, v_pos, 1) = ''1'' then
      v_pos := v_pos + 32;
    else
      v_pos := v_pos + 8;
    end if;
  end loop;

  if v_level < p_level then
    raise exception ''tree_key_to_int: key is at a level less than %'', p_level;
  end if;

  if substring(p_tree_key, v_parent_pos, 1) = ''1'' then
    return bittoint4(substring(p_tree_key, v_parent_pos + 1, 31));
  else
    return bittoint4(substring(p_tree_key, v_parent_pos, 8));
  end if;

end;' language 'plpgsql' immutable strict;

create or replace function tree_ancestor_key(varbit, integer) returns varbit as '

-- Returns a key for the ancestor at the given level.  The root is level
-- one.

declare
  p_tree_key      alias for $1;
  p_level         alias for $2;
  v_level         integer default 0;
  v_pos           integer default 1;
begin

  if tree_level(p_tree_key) < p_level then
    raise exception ''tree_ancestor_key: key is at a level less than %'', p_level;
  end if;

  while v_level < p_level loop
    v_level := v_level + 1;
    if substring(p_tree_key, v_pos, 1) = ''1'' then
      v_pos := v_pos + 32;
    else
      v_pos := v_pos + 8;
    end if;
  end loop;

  return substring(p_tree_key, 1, v_pos - 1);

end;' language 'plpgsql' immutable strict;

create or replace function tree_root_key(varbit) returns varbit as '

-- Return the tree_sortkey for the root node of the node with the 
-- given tree_sortkey.  

declare
  p_tree_key      alias for $1;
begin

  if substring(p_tree_key, 1, 1) = ''1'' then
      return substring(p_tree_key, 1, 32);
  else
      return substring(p_tree_key, 1, 8);
  end if;

end;' language 'plpgsql' immutable strict;

create or replace function tree_leaf_key_to_int(varbit) returns integer as '

-- Convert the bitstring for the last, or leaf, node represented by this key
-- to an integer.

declare
  p_tree_key      alias for $1;
  v_leaf_pos      integer default 1;
  v_pos           integer default 1;
begin

  -- Find the leaf key first
  while v_pos < length(p_tree_key) loop
    v_leaf_pos := v_pos;
    if substring(p_tree_key, v_pos, 1) = ''1'' then
      v_pos := v_pos + 32;
    else
      v_pos := v_pos + 8;
    end if;
  end loop;

  if substring(p_tree_key, v_leaf_pos, 1) = ''1'' then
    return bittoint4(substring(p_tree_key, v_leaf_pos + 1, 31));
  else
    return bittoint4(substring(p_tree_key, v_leaf_pos, 8));
  end if;

end;' language 'plpgsql' immutable strict;

create or replace function tree_next_key(varbit, integer) returns varbit as '
declare
  p_parent_key      alias for $1;
  p_child_value     alias for $2;
  v_child_value     integer;
begin
-- Create a new child of the given key with a leaf key number one greater than
-- the child value parameter.  If the child value parameter is null, make the
-- child the first child of the parent.

  if p_child_value is null then
    v_child_value := 0;
  else
    v_child_value := p_child_value + 1;
  end if;

  if p_parent_key is null then
    return int_to_tree_key(v_child_value);
  else
    return p_parent_key || int_to_tree_key(v_child_value);
  end if;

end;' language 'plpgsql' immutable;

create or replace function tree_increment_key(varbit)
returns varbit as '
declare
    p_child_sort_key                alias for $1;
    v_child_sort_key                integer;
begin
    if p_child_sort_key is null then
        v_child_sort_key := 0;
    else
        v_child_sort_key := tree_leaf_key_to_int(p_child_sort_key) + 1;
    end if;

    return int_to_tree_key(v_child_sort_key);
end;' language 'plpgsql' immutable;

create or replace function tree_left(varbit) returns varbit as '

-- Create a key less than or equal to that of any child of the
-- current key.

declare
  key      alias for $1;
begin
  if key is null then
    return ''X00''::varbit;
  else
    return key || ''X00''::varbit;
  end if;
end;' language 'plpgsql' immutable;

create or replace function tree_right(varbit) returns varbit as '

-- Create a key greater or equal to that of any child of the current key.
-- Used in BETWEEN expressions to select the subtree rooted at the given
-- key. 

declare
  key      alias for $1;
begin
  if key is null then
    return ''XFFFFFFFF''::varbit;
  else
    return key || ''XFFFFFFFF''::varbit;
  end if;
end;' language 'plpgsql' immutable;

create or replace function tree_level(varbit) returns integer as '

-- Return the tree level of the given key.  The root level is defined
-- to be at level one.

declare
  p_tree_key           alias for $1;
  v_pos                integer;        
  v_level              integer;
  
begin

  if p_tree_key is null then
    return 0;
  end if;

  v_pos := 1;
  v_level := 0;

  while v_pos <= length(p_tree_key) loop
    v_level := v_level + 1;
    if substring(p_tree_key, v_pos, 1) = ''1'' then
      v_pos := v_pos + 32;
    else
      v_pos := v_pos + 8;
    end if;
  end loop;

  return v_level;
end;' language 'plpgsql' immutable;

create or replace function tree_ancestor_p(varbit, varbit) returns boolean as '
declare
  p_potential_ancestor      alias for $1;
  p_potential_child         alias for $2;
begin
  return position(p_potential_ancestor in p_potential_child) = 1;
end;' language 'plpgsql' immutable;

-- PG does not allow recursive SQL functions during CREATE, but you can fool it easily
-- with CREATE OR REPLACE, a feature added in 7.2.

-- tree_ancestor_keys(varbit, integer) returns the set of ancestor keys starting at
-- the level passed in as the second parameter down to the key passed in as the first

-- This function should probably only be called from its overloaded cousin
-- tree_ancestor_keys(varbit), which returns the set of tree_sortkeys for all of the
-- ancestors of the given tree_sortkey...

create or replace function tree_ancestor_keys(varbit, integer) returns setof varbit as '
  select $1
' language 'sql';

-- The bootstrap installer has made certain that we are running a version >= 7.2 so it is safe
-- at this point to assume create or replace is supported.

create or replace function tree_ancestor_keys(varbit, integer) returns setof varbit as '
  select tree_ancestor_key($1, $2)
  union
  select tree_ancestor_keys($1, $2 + 1)
  where $2 < tree_level($1)
' language 'sql' immutable strict;


------------------------------
-- TREE_ANCESTOR_KEYS

-- Return the set of tree_sortkeys for all of the ancestors of the given
-- tree_sortkey ancestors.

-- Here is an example on acs_objects:

-- select o.*
-- from acs_objects o,
--   (select tree_ancestor_keys(acs_objects_get_tree_sortkey(:object_id)) as tree_sortkey) parents
-- where o.tree_sortkey = parents.tree_sortkey;

-- This query will use the index on tree_sortkey to scan acs_objects.  The function to grab
-- the tree_sortkey for the node is necessary (and must be defined for each table that uses
-- our hierarchical query scheme) to avoid restrictions on the use of SQL functions that
-- return sets.

-- if you only want the ancestors for a node within a given subtree, do something like this and
-- cross your fingers that Postgres will figure out whether the join on parent or the root is
-- more restrictive and do the right one first:

-- select o.*
-- from acs_objects o,
--     (select tree_sortkey from acs_objects where object_id = :root_id) as root
--   (select tree_ancestor_keys(acs_objects_get_tree_sortkey(:object_id)) as tree_sortkey) parents
-- where o.tree_sortkey = parents.tree_sortkey
--   and o.tree_sortkey >= root.tree_sortkey;

-- DO NOT BE TEMPTED TO REWRITE THE ABOVE QUERIES LIKE THIS:

-- select *
-- from acs_objects
-- where object_id in (select tree_ancestor_keys(object_id)
--                     from acs_objects
--                     where object_id = :object_id);

-- This is more readable and is certainly cleaner BUT WILL NOT USE THE INDEX ON TREE_SORTKEY
-- when scanning the acs_objects instance referred to by the left operand of the "in" operator.  Given
-- that acs_objects will become HUGE on real systems the resulting sequential scan would cripple
-- performance.   

-- WARNING: subselects in where clauses that call this function and join on an outer table appear
-- to reliably kill PG 7.1.2, at least if "exists" is involved.   PG 7.2 doesn''t die on my test
-- case, so it appears to have been fixed.
create or replace function tree_ancestor_keys(varbit) returns setof varbit as '

  select tree_ancestor_keys($1, 1)

' language 'sql' immutable strict;

----------------------------------------------------------------------------

-- PG substitute for Oracle user_tab_columns view

create view user_tab_columns as
  select upper(c.relname) as table_name,
	 upper(a.attname) as column_name,
	 upper(t.typname) as data_type
    from pg_class c, pg_attribute a, pg_type t
   where c.oid = a.attrelid
     and a.atttypid = t.oid
     and a.attnum > 0;

-- PG substitute for Oracle user_col_comments view

create view user_col_comments as
  select upper(c.relname) as table_name, 
    upper(a.attname) as column_name, 
    col_description(a.attrelid, a.attnum) as comments
  from pg_class c left join pg_attribute a on a.attrelid = c.oid 
  where a.attnum > 0;

-- PG substitute for Oracle user_col_comments view

create view user_tab_comments as
  select upper(c.relname) as table_name,
    case
      when c.relkind = 'r' then 'TABLE'
      when c.relkind = 'v' then 'VIEW'
      else c.relkind::text
    end as table_type,
    d.description as comments
  from pg_class c left outer join pg_description d on (c.oid = d.objoid)
  where d.objsubid = 0;

-- Table for storing PL/PGSQL function arguments

create table acs_function_args (
       function              varchar(100) not null,
       arg_seq		     integer not null,
       arg_name		     varchar(100),
       arg_default	     varchar(100),
       constraint acs_function_args_pk
       primary key (function, arg_seq),
       constraint acs_function_args_un
       unique (function, arg_name)
);


-- Add entries to acs_function_args for one function
-- Usage: select define_function_args('function_name','arg1,arg2;default,arg3,arg4;default')

create or replace function define_function_args(varchar,varchar)
returns integer as '
declare
  p_function            alias for $1;
  p_arg_list            alias for $2;

  v_arg_seq             integer default 1;
  v_arg_name            varchar;
  v_arg_default         varchar;
  v_elem                varchar;
  v_pos                 integer;
begin
  delete from acs_function_args where function = upper(trim(p_function));

  v_elem = split(p_arg_list, '','', v_arg_seq);
  while v_elem is not null loop
    
    v_pos = instr(v_elem, '';'', 1, 1);
    if v_pos > 0 then
      v_arg_name := substr(v_elem, 1, v_pos-1);
      v_arg_default := substr(v_elem, v_pos+1, length(v_elem) - v_pos);
    else
      v_arg_name := v_elem;
      v_arg_default := NULL;
    end if;

    insert into acs_function_args (function, arg_seq, arg_name, arg_default)
	   values (upper(trim(p_function)), v_arg_seq, upper(trim(v_arg_name)), v_arg_default);

    v_arg_seq := v_arg_seq + 1;
    v_elem = split(p_arg_list, '','', v_arg_seq);
  end loop;
    
  return 1;
end;' language 'plpgsql';

-- Returns an english-language description of the trigger type.  Used by the
-- schema browser

create or replace function trigger_type (integer) returns varchar as '
declare
  tgtype            alias for $1;
  description       varchar;
  sep               varchar;
begin

 if (tgtype & 2) > 0 then
    description := ''BEFORE '';
 else 
    description := ''AFTER '';
 end if;

 sep := '''';

 if (tgtype & 4) > 0 then
    description := description || ''INSERT '';
    sep := ''OR '';
 end if;

 if (tgtype & 8) > 0 then
    description := description || sep || ''DELETE '';
    sep := ''OR '';
 end if;

 if (tgtype & 16) > 0 then
    description := description || sep || ''UPDATE '';
    sep := ''OR '';
 end if;

 if (tgtype & 1) > 0 then
    description := description || ''FOR EACH ROW'';
 else
    description := description || ''STATEMENT'';
 end if;

 return description;

end;' language 'plpgsql' with (iscachable);

