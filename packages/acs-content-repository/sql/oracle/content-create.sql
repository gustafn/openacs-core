-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

----------------------------------
-- CMS datatypes
----------------------------------

-- create ats datatypes for cms
begin
  insert into acs_datatypes
    (datatype, max_n_values)
  values
    ('text', null);

  insert into acs_datatypes
    (datatype, max_n_values)
  values
    ('keyword', 1);

end;
/


--------------------------------------------------------------
-- MIME TYPES
--------------------------------------------------------------

create table cr_mime_types (
  label			varchar2(200),
  mime_type	        varchar2(200)
			constraint cr_mime_types_pk
			primary key,
  file_extension        varchar2(200)
);


comment on table cr_mime_types is '
  Standard MIME types recognized by the content management system.
';

comment on table cr_mime_types is '
  file_extension is not used to recognize MIME types, but to associate
  a file extension to the file after its MIME type is specified.
';

-- Common mime types (administered from admin pages)

insert into cr_mime_types values ('Plain text', 'text/plain', 'txt');
insert into cr_mime_types values ('HTML text', 'text/html', 'html');
insert into cr_mime_types values ('Rich Text Format (RTF)', 'text/richtext', 'rtf');

create table cr_content_mime_type_map (
  content_type  varchar2(100)
		constraint cr_content_mime_map_ctyp_fk
		references acs_object_types,
  mime_type	varchar2(200)
		constraint cr_content_mime_map_typ_fk
		references cr_mime_types,
  constraint cr_content_mime_map_pk
  primary key (content_type, mime_type)
);

comment on table cr_content_mime_type_map is '
  A mapping table that restricts the MIME types associated with a 
  content type.
';



--------------------------------------------------------------
-- LOCALES
--------------------------------------------------------------

create table cr_locales (
  locale		varchar2(4)
                        constraint cr_locale_abbrev_pk
                        primary key,
  label			varchar2(200)
                        constraint cr_locale_name_nil
			not null
                        constraint cr_locale_name_unq
                        unique,
  nls_language		varchar2(30)
                        constraint cr_locale_nls_lang_nil
			not null,
  nls_territory		varchar2(30),
  nls_charset		varchar2(30)
);

comment on table cr_locales is '
  Locale definitions in Oracle consist of a language, and optionally
  territory and character set.  (Languages are associated with default
  territories and character sets when not defined).  The formats
  for numbers, currency, dates, etc. are determined by the territory.
';

insert into cr_locales (
  locale, label, nls_language, nls_territory, nls_charset
) values (
  'us', 'American', 'AMERICAN', 'AMERICA', 'WE8ISO8859P1'
);

--------------------------------------------------------------
-- CONTENT TYPES
--------------------------------------------------------------

create table cr_type_children (
  parent_type   varchar2(100)
		constraint cr_type_children_parent_fk
		references acs_object_types,
  child_type    varchar2(100)
		constraint cr_type_children_child_fk
		references acs_object_types,
  relation_tag  varchar2(100),
  min_n         integer,
  max_n         integer,
  constraint cr_type_children_pk
  primary key (parent_type, child_type, relation_tag)
);

comment on table cr_type_children is '
  Constrains the allowable content types which a content type may
  contain.
';

create table cr_type_relations (
  content_type  varchar2(100)
		constraint cr_type_relations_parent_fk
		references acs_object_types,
  target_type   varchar2(100)
		constraint cr_type_relations_child_fk
		references acs_object_types,
  relation_tag  varchar2(100),
  min_n         integer,
  max_n         integer,
  constraint cr_type_relations_pk
  primary key (content_type, target_type, relation_tag)
);

comment on table cr_type_relations is '
  Constrains the allowable object types to which a content type may
  relate (see above).
';

--------------------------------------------------------------
-- CONTENT ITEMS
--------------------------------------------------------------

-- Define the cr_items table

create table cr_items (
  item_id	  integer 
                  constraint cr_items_item_id_fk references
		  acs_objects on delete cascade
		  constraint cr_items_pk primary key,
  parent_id	  integer 
                  constraint cr_items_parent_id_nil 
                  not null
                  constraint cr_items_parent_id_fk references
		  acs_objects on delete cascade,
  name		  varchar2(400)
		  constraint cr_items_name_nil
                  not null,
  locale	  varchar2(4)
		  constraint cr_items_locale_fk references
		  cr_locales,
  live_revision   integer,
  latest_revision integer,
  publish_status  varchar2(40) 
                  constraint cr_items_pub_status_chk
                  check (publish_status in 
                    ('production', 'ready', 'live', 'expired')
                  ),
  content_type    varchar2(100)
                  constraint cr_items_rev_type_fk
                  references acs_object_types,
  storage_type    varchar2(10) default 'lob' not null
                  constraint cr_revisions_storage_type
                  check (storage_type in ('lob','file'))
);  

create index cr_items_by_locale on cr_items(locale);
create index cr_items_by_content_type on cr_items(content_type);
create unique index cr_items_by_live_revision on cr_items(live_revision);
create unique index cr_items_by_latest_revision on cr_items(latest_revision);
create unique index cr_items_unique_name on cr_items(parent_id, name);
create unique index cr_items_unique_id on cr_items(parent_id, item_id);
create index cr_items_by_parent_id on cr_items(parent_id);

comment on table cr_items is '
  Each content item has a row in this table, as well as a row in
  the acs_objects table.  The parent_id is used to place an
  item in a directory or place it within another container item.
';

comment on column cr_items.content_type is '
  The content type constrains the type of revision that may be
  added to this item (an item should have revisions of only one type).
  If null, then no revisions should be allowed.
';

create table cr_child_rels (
  rel_id             integer
                     constraint cr_child_rels_rel_pk
                     primary key
                     constraint cr_child_rels_rel_fk
                     references acs_objects,
  parent_id          integer
                     constraint cr_child_rels_parent_nil
                     not null,
  child_id           integer
                     constraint cr_child_rels_child_nil
                     not null,
  relation_tag       varchar2(100),
  order_n            integer
);

create index cr_child_rels_by_parent on cr_child_rels(parent_id);
create unique index cr_child_rels_unq_id on cr_child_rels(parent_id, child_id);

comment on table cr_child_rels is '
  Provides for richer parent-child relationships than the simple
  link encapsulated in the primary table.  May be subclassed to provide
  additional attributes.
';

create table cr_item_rels (
  rel_id             integer
                     constraint cr_item_rels_pk
                     primary key
                     constraint cr_item_rels_fk
                     references acs_objects,
  item_id            integer
                     constraint cr_item_rels_item_fk
                     references cr_items,
  related_object_id  integer
                     constraint cr_item_rels_rel_obj__fk
                     references acs_objects,
  relation_tag       varchar2(100),
  order_n            integer
);

create unique index cr_item_rel_unq on cr_item_rels (
  item_id, related_object_id, relation_tag
);

comment on table cr_item_rels is '
  Describes all relations from one item to any number of other
  objects.
';

comment on column cr_item_rels.relation_tag is '
  A token for lightweight classification of item relationships.
  If additional attributes are required, then a subtype of
  item_rel may be created.
';

comment on column cr_item_rels.order_n is '
  Optional column for specifying a sort order.  Note that the ordering
  method is application-dependent (it may be by relation type or
  across multiple relation types).
';

--------------------------------------------------------------
-- CONTENT REVISIONS
--------------------------------------------------------------

-- Define the cr_revisions table

create table cr_revisions (
  revision_id     constraint cr_revisions_rev_id_fk references
		  acs_objects (object_id) on delete cascade
		  constraint cr_revisions_pk primary key,
  item_id         constraint cr_revisions_item_id_nil
                  not null
                  constraint cr_revisions_item_id_fk references
		  cr_items on delete cascade,
  title		  varchar2(1000),
  description	  varchar2(4000),
  publish_date	  date,
  mime_type	  varchar2(200) default 'text/plain'
		  constraint cr_revisions_mime_type_ref
		  references cr_mime_types,
  nls_language    varchar2(50),
  filename        varchar2(4000),
  content	  BLOB,
  content_length  integer
);


create index cr_revisions_by_mime_type on cr_revisions(mime_type);
create index cr_revisions_title_idx on cr_revisions(title);
-- create index cr_revisions_lower_title_idx on cr_revisions(lower(title));
-- create index cr_revisions_title_ltr_idx on cr_revisions(substr(lower(title), 1, 1));

comment on table cr_revisions is '
  Each content item may be associated with any number of revisions.
  The item_id is used to associate revisions with an item.
';

comment on column cr_revisions.nls_language  is '
  NLS_LANGUAGE is required in the same table as the content column
  for multi-lingual searching in Intermedia.
';

alter table cr_items add constraint cr_items_live_fk 
  foreign key (live_revision) references cr_revisions(revision_id);

alter table cr_items add constraint cr_items_latest_fk 
  foreign key (latest_revision) references cr_revisions(revision_id);

create table cr_revision_attributes (
  revision_id    integer
                 constraint cr_revision_attributes_pk
                 primary key
                 constraint cr_revision_attributes_fk
                 references cr_revisions,
  attributes     clob
);

comment on column cr_revision_attributes.attributes is '
  An XML document representing the compiled attributes for a revision
';

create global temporary table cr_content_text (
    revision_id        integer primary key,
    content            CLOB
) on commit delete rows;

comment on table cr_content_text is '
  A temporary table for holding text extracted from the content blob.
  Provides a workaround for the fact that blob_to_string(content) has
  4000 character limit.
';

--------------------------------------------------------------
-- CONTENT PUBLISHING
--------------------------------------------------------------

create table cr_item_publish_audit (
  item_id            integer
                     constraint cr_item_publish_audit_fk
                     references cr_items on delete cascade, 
  old_revision       integer
                     constraint cr_item_pub_audit_old_rev_fk
                     references cr_revisions, 
  new_revision       integer
                     constraint cr_item_pub_audit_new_rev_fk
                     references cr_revisions, 
  old_status         varchar2(40),
  new_status         varchar2(40),
  publish_date       date
                     constraint cr_item_publish_audit_date_nil
                     not null
);

create index cr_item_publish_audit_idx on cr_item_publish_audit(item_id);

comment on table cr_item_publish_audit is '
  An audit table (populated by a trigger on cr_items.live_revision)
  that is used to keep track of the publication history of an item.
';

create table cr_release_periods (
  item_id          integer
                   constraint cr_release_periods_fk
		   references cr_items
                   constraint cr_release_periods_pk
		   primary key,
  start_when	   date default sysdate,
  end_when	   date default sysdate + (365 * 20)
);

create table cr_scheduled_release_log (
  exec_date        date default sysdate not null,
  items_released   integer not null,
  items_expired    integer not null,
  err_num          integer,
  err_msg          varchar2(500)
);

comment on table cr_scheduled_release_log is '
  Maintains a record, including any exceptions that may
  have aborted processing, for each scheduled update of live content.
';

create table cr_scheduled_release_job (
  job_id     integer,
  last_exec  date
);

comment on table cr_scheduled_release_job is '
  One-row table to track job ID of scheduled release update.
';

insert into cr_scheduled_release_job values (NULL, sysdate);

--------------------------------------------------------------
-- CONTENT FOLDERS
--------------------------------------------------------------

create table cr_folders (
  folder_id	    integer
		    constraint cr_folder_id_fk references
		    cr_items on delete cascade
		    constraint cr_folders_pk 
                    primary key,
  label		    varchar2(1000),
  description	    varchar2(4000),
  has_child_folders char(1)
                    default 'f'
                    constraint cr_folder_child_chk
                    check (has_child_folders in ('t','f')),
  has_child_symlinks char(1)
                     default 'f'
                     constraint cr_folder_symlink_chk
                     check (has_child_symlinks in ('t', 'f'))
);  

comment on table cr_folders is '
  Folders are used to support a virtual file system within the content
  repository.
';


create table cr_folder_type_map (
  folder_id	integer
		constraint cr_folder_type_map_fldr_fk
		references cr_folders,
  content_type  varchar2(100)
		constraint cr_folder_type_map_typ_fk
		references acs_object_types,
  constraint cr_folder_type_map_pk
  primary key (folder_id, content_type)
);

comment on table cr_folder_type_map is '
  A one-to-many mapping table of content folders to content types. 
  Basically, this table restricts the content types a folder may contain.
  Future releases will add numeric and tagged constraints similar to
  thos available for content types.  
';




--------------------------------------------------------------
-- CONTENT TEMPLATES
--------------------------------------------------------------

create table cr_templates (
  template_id	  integer
		  constraint cr_template_id_fk references
		  cr_items on delete cascade
		  constraint cr_templates_pk 
                  primary key
);

comment on table cr_templates is '
  Templates are a special class of text objects that are used for specifying
  the layout of a content item.  They may be mapped to content types for
  defaults, or may be mapped to individual content items.
';

create table cr_template_use_contexts (
  use_context	   varchar2(100)
                   constraint cr_template_use_contexts_pk
                   primary key
);

comment on table cr_template_use_contexts is '
  A simple table (for now) for constraining template use contexts.
';

insert into cr_template_use_contexts values ('admin');
insert into cr_template_use_contexts values ('public');

create table cr_type_template_map (
  content_type     varchar2(100)
                   constraint cr_type_template_map_typ_fk
                   references acs_object_types
                   constraint cr_type_template_map_typ_nil
                   not null,
  template_id      integer
                   constraint cr_type_template_map_tmpl_fk
	           references cr_templates,
  use_context	   varchar2(100)
                   constraint cr_type_template_map_ctx_nil
                   not null
                   constraint cr_type_template_map_ctx_fk
                   references cr_template_use_contexts,
  is_default	   char(1)
                   default 'f'
                   constraint cr_type_template_map_def_ck
                   check (is_default in ('t','f')),
  constraint cr_type_template_map_pk
    primary key (content_type, template_id, use_context)
);

create index cr_ttmap_by_content_type on cr_type_template_map(content_type);
create index cr_ttmap_by_template_id on cr_type_template_map(template_id);
create index cr_ttmap_by_use_context on cr_type_template_map(use_context);

comment on table cr_type_template_map is '
  A simple mapping template among content types and templates.
  Used to determine the default template to use in any particular
  context, as well as for building any UI that allows publishers
  to choose from a palette of templates.
';

comment on column cr_type_template_map.use_context is '
  A token to indicate the context in which a template is appropriate, 
  such as admin or public.  Should be constrained when it becomes
  clearer how this will be used.
';

create table cr_item_template_map (
  item_id          integer
                   constraint cr_item_template_map_item_fk
                   references cr_items
                   constraint cr_item_template_map_item_nil
                   not null,
  template_id      integer
                   constraint cr_item_template_map_tmpl_fk
	           references cr_templates
                   constraint cr_item_template_map_tmpl_nil
                   not null,
  use_context	   varchar2(100)
                   constraint cr_item_template_map_ctx_nil
                   not null
                   constraint cr_item_template_map_ctx_fk
                   references cr_template_use_contexts,
  constraint cr_item_template_map_pk
  primary key (item_id, template_id, use_context)
);

create index cr_itmap_by_item_id on cr_item_template_map(item_id);
create index cr_itmap_by_template_id on cr_item_template_map(template_id);
create index cr_itmap_by_use_context on cr_item_template_map(use_context);

comment on table cr_item_template_map is '
  Allows a template to be assigned to a specific item.
';

--------------------------------------------------------------
-- CONTENT SYMLINKS
--------------------------------------------------------------

create table cr_symlinks (
  symlink_id	  integer
		  constraint cr_symlink_id_fk references
		  cr_items on delete cascade
		  constraint cr_symlinks_pk 
                  primary key,
  target_id       integer
                  constraint cr_symlink_target_id_fk
		  references cr_items
		  constraint cr_symlink_target_id_nil
		  not null,
  label		  varchar2(1000)
);

create index cr_symlinks_by_target_id on cr_symlinks(target_id);

comment on table cr_symlinks is '
  Symlinks are pointers to items within the content repository.
';

--------------------------------------------------------------
-- CONTENT EXTLINKS
--------------------------------------------------------------

create table cr_extlinks (
  extlink_id	  integer
		  constraint cr_extlink_id_fk references
		  cr_items on delete cascade
		  constraint cr_extlinks_pk 
                  primary key,
  url             varchar2(1000)
		  constraint cr_extlink_url_nil
		  not null,
  label           varchar2(1000)
		  constraint cr_extlink_label_nil
		  not null,
  description	  varchar2(4000)
);

comment on table cr_extlinks is '
  Extlinks are pointers to items anywhere on the web which the publisher wishes
  to categorize, index and relate to items in the content repository.
';

--------------------------------------------------------------
-- CONTENT KEYWORDS
--------------------------------------------------------------

create table cr_keywords (
  keyword_id		 integer
			 constraint cr_keywords_pk
		         primary key,
  parent_id              integer 
                         constraint cr_keywords_hier
                         references cr_keywords,
  heading		 varchar2(600)
			 constraint cr_keywords_name_nil
			 not null,
  description            varchar2(4000),
  has_children           char(1)
                         constraint cr_keywords_child_chk
                         check (has_children in ('t', 'f'))
);

comment on table cr_keywords is '
  Stores a subject taxonomy for classifying content items, analogous
  to the system used by a library.
';

comment on column cr_keywords.heading is '
  A subject heading.  This will become a message ID in the next
  release so it should never be referenced directly (only through
  the API)
';

comment on column cr_keywords.description is '
  Description of a subject heading.  This will be a message ID in the next
  release so it should never be referenced directly (only through
  the API)
';

create table cr_item_keyword_map (
  item_id          integer
                   constraint cr_item_keyword_map_item_fk
                   references cr_items
                   constraint cr_item_keyword_map_item_nil
                   not null,
  keyword_id       integer
                   constraint cr_item_keyword_map_kw_fk
	           references cr_keywords
                   constraint cr_item_keyword_map_kw_nil
                   not null,
  constraint cr_item_keyword_map_pk
  primary key (item_id, keyword_id)
);


--------------------------------------------------------------
-- TEXT SUBMISSION
--------------------------------------------------------------

create table cr_text ( 
  text varchar2(4000)
);

comment on table cr_text is '
  A simple placeholder table for generating input views, so that a
  complete revision may be added with a single INSERT statement.
';

insert into cr_text values (NULL);

create or replace trigger cr_text_tr
before insert on cr_text
for each row
begin

   raise_application_error(-20000,
        'Inserts are not allowed into cr_text.'
      );
end;
/
show errors



--------------------------------------------------------------
-- DOCUMENT SUBMISSION WITH CONVERSION TO HTML
--------------------------------------------------------------

create global temporary table cr_doc_filter (
    revision_id        integer primary key,
    content            BLOB
) on commit delete rows;


-- Source PL/SQL Definitions.

@@ content-util
@@ content-xml

prompt *** Creating packaged call specs for Java utility methods...
@@ content-package

prompt *** Defining and compiling packages...
@@ packages-create

prompt *** Creating object types...
@@ types-create

prompt *** Preparing search indices...
@@ content-search

-- this index requires prefs created in content-search
create index cr_doc_filter_index on cr_doc_filter ( content )
  indextype is ctxsys.context
  parameters ('FILTER content_filter_pref' );

comment on table cr_doc_filter is '
  A temporary table for holding binary documents that are to be converted
  into HTML (or plain text) prior to insertion into the repository.
';



prompt *** Compiling documentation package...
@@ doc-package

prompt *** Creating image content type...
@@ content-image

-- by default, map all MIME types to 'content_revision'

begin
  content_type.register_mime_type(
    content_type => 'content_revision', mime_type => 'text/html');
  content_type.register_mime_type(
    content_type => 'content_revision', mime_type => 'text/plain');
end;
/
show errors

prompt *** Initializing content repository hierarchy...

-- Create the default folders
declare
  v_id integer;
begin

  v_id := content_folder.new (
    name        => 'pages',
    label       => 'Pages', 
    description => 'Site pages go here',
    parent_id   => 0,
    folder_id   => content_item.get_root_folder
  );

  content_folder.register_content_type(
    folder_id        => v_id,
    content_type     => 'content_revision',
    include_subtypes => 't'
  );

  content_folder.register_content_type(
    folder_id        => v_id,
    content_type     => 'content_folder',
    include_subtypes => 't'
  );

  content_folder.register_content_type(
    folder_id        => v_id,
    content_type     => 'content_symlink',
    include_subtypes => 't'
  );

  v_id := content_folder.new (
    name        => 'templates',
    label       => 'Templates', 
    description => 'Templates which render the pages go here',
    parent_id   => 0,
    folder_id   => content_template.get_root_folder
  );

  content_folder.register_content_type(
    folder_id        => v_id,
    content_type     => 'content_folder',
    include_subtypes => 't'
  );

  content_folder.register_content_type(
    folder_id        => v_id,
    content_type     => 'content_symlink',
    include_subtypes => 't'
  );

  content_folder.register_content_type(
    folder_id        => v_id,
    content_type     => 'content_template',
    include_subtypes => 't'
  );

end;
/
show errors


