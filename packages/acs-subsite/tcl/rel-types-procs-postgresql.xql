<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_type_dynamic_p">      
      <querytext>
      
	select case when exists (select 1 
                                   from acs_object_types t
                                  where t.dynamic_p = 't'
                                    and t.object_type = :value)
	            then 1 else 0 end
	  
    
      </querytext>
</fullquery>

 
<fullquery name="rel_types::additional_rel_types_group_type_p.group_rel_type_exists">      
      <querytext>

             select case when exists (select 1
                                        from acs_object_types t1, acs_object_types t2
                                       where t2.object_type not in (select g.rel_type
                                                                      from group_type_rels g
                                                                     where g.group_type = :group_type)
					 and t1.object_type in ('membership_rel','composition_rel')
					 and t2.tree_sortkey like t1.tree_sortkey || '%')
                    then 1 else 0 end
      
      </querytext>
</fullquery>

<fullquery name="rel_types::new.drop_type">
<querytext>
	select acs_rel_type__drop_type(:rel_type)
</querytext>
</fullquery>

<fullquery name="rel_types::new.create_type">
<querytext>
select acs_rel_type__create_type (	
	:rel_type,
	:pretty_name,
	:pretty_plural,
	:supertype,
	:table_name,
	'rel_id',
	:package_name,
	:object_type_one,
	:role_one,
	:min_n_rels_one,
	:max_n_rels_one,
	:object_type_two,
	:role_two,
	:min_n_rels_two,
	:max_n_rels_two
);
</querytext>
</fullquery>

 
</queryset>
