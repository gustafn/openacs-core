ad_page_contract {
    Create and mount a new Subsite/Community.

    @author Steffen Tiedemann Christensen (steffen@christensen.name)
    @creation-date 2003-09-26
} {
    node_id:integer,optional
}

auth::require_login

if { [string equal [ad_conn package_url] "/"] } {
    set page_title "New community"
    set subsite_pretty_name "Community name"
} else {
    set page_title "New subcommunity"
    set subsite_pretty_name "Subcommunity name"
}
set context [list $page_title]


ad_form -name subsite -cancel_url . -form {
    {node_id:key}
    {instance_name:text
        {label $subsite_pretty_name}
        {help_text "The name of the new community you're setting up."}
        {html {size 30}}
    }
    {folder:url_element(text),optional
        {label "URL folder name"}
        {help_text "This should be a short string, all lowercase, with hyphens instead of spaces, whicn will be used in the URL of the new application. If you leave this blank, we will generate one for you from name of the application."}
        {html {size 30}}
    }
    {master_template:text(select)
        {label "Template"}
        {help_text "Choose the layout and navigation you want for your community."}
        {options [subsite::get_template_options]}
    }
    {visibility:text(select)
        {label "Visible to"}
        {options { { "Members only" "members" } { "Anyone" "any" } }}
    }
    {join_policy:text(select)
        {label "Join policy"}
        {options [group::get_join_policy_options]}
    }
} -on_submit {
    set folder [site_node::verify_folder_name \
                    -parent_node_id [ad_conn node_id] \
                    -current_node_id $node_id \
                    -folder $folder \
                    -instance_name $instance_name]

    if { [empty_string_p $folder] } {
        form set_error subsite folder "This folder name is already used"
        break
    }
} -new_data {
    db_transaction {
        # Create and mount new subsite
        set new_package_id [site_node::instantiate_and_mount \
                                -parent_node_id [ad_conn node_id] \
                                -node_name $folder \
                                -package_name $instance_name \
                                -package_key acs-subsite]
        
        # Set template
        parameter::set_value -parameter DefaultMaster -package_id $new_package_id -value $master_template

        # Set join policy
        set group(join_policy) $join_policy
        set member_group_id [application_group::group_id_from_package_id -package_id $new_package_id]
        group::update -group_id $member_group_id -array group

        # Add current user as admin
	set rel_id [relation_add -member_state "approved" "admin_rel" $member_group_id [ad_conn user_id]]
        
        # Set inheritance (called 'visibility' in form)
        if { ![string equal $visibility "any"] } {
            permission::set_not_inherit -object_id $new_package_id
        }
        
    } on_error {
        ad_return_error "Problem Creating Application" "We had a problem creating the community."
    }
} -after_submit {
    ad_returnredirect ../$folder
    ad_script_abort
}
