# Interface to the ACS for the ArsDigita Templating System
# Procedures in this file only make sense if you use the template system
# together with the ArsDigita Community System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Christian Brechbuehler <christian@arsdigita.com

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc -public ad_return_template {
     -string:boolean
    {template ""}
} {
    This function is a wrapper for sundry template:: procs. Will set the 
    template for the current page to the file named in 'template'. 

    @param template Name of template file 

    @param string If specified, will return the resulting page to the caller
                  string instead sending it to the connection.
} {
    if {![empty_string_p $template]} {
	template::set_file \
	    [template::util::url_to_file $template [ad_conn file]]
    }
    
    if { $string_p } {
	return [template::adp_parse \
		    [template::util::url_to_file $template [ad_conn file]] {}]
    }
}

ad_proc -public ad_parse_template {
    {-params ""}
    template
} {
    Return a string containing the parsed and evaluated template to the caller.

    @param params The parameters to pass to the template.

    @param template The template file name.

    Example:

    <code>set page [ad_parse_template -params {errmsg {custom_message "My Message"}} some-template]</code>

    @param template Name of template file
} {
    set template_params [list]
    foreach param $params {
        switch [llength $param] {
            1 { lappend template_params "&"
                lappend template_params [lindex $param 0]
              }
            2 { lappend template_params [lindex $param 0]
                lappend template_params [lindex $param 1]
              }
            default { return -code error "Error in parameter list" }
        }
    }
    return [uplevel [list template::adp_parse [template::util::url_to_file $template [ad_conn file]] $template_params]]
}


ad_proc -public ad_return_exception_template {
    {-status 500}
    {-params ""}
    template
} {
    Return an exception template and abort the current script.

    @param status The HTTP status to return, by default HTTP 500 (Error)
    @param params The parameters to pass to the template.
    @param template The template file name.

    Example:

    <code>ad_return_exception_template -params {errmsg {custom_message "My Message"}} some-template</code>
} {
    ns_return $status text/html [ad_parse_template -params $params $template]
    ad_script_abort
}

ad_proc -public get_server_root {} {
    Get the server root directory (supposing we run under ACS)
} {
    file dir [ns_info tcllib]
}


ad_proc adp_parse_ad_conn_file {} {
    handle a request for an adp and/or tcl file in the template system.
} {
    namespace eval template variable parse_level ""
    #ns_log debug "adp_parse_ad_conn_file => file '[file root [ad_conn file]]'"
    # Pull out the package_id of the subsite closest to our current node
    ad_conn -set subsite_id [site_node_closest_ancestor_package "acs-subsite"]

    set parsed_template [template::adp_parse [file root [ad_conn file]] {}]

    if {![empty_string_p $parsed_template]} {
        set mime_type [template::get_mime_type]
        set header_preamble [template::get_mime_header_preamble $mime_type]
	doc_return 200 $mime_type "$header_preamble $parsed_template"
    } else {
        db_release_unused_handles
    }
}

ad_proc -public -deprecated -warn ad_template_return {{file_stub ""}} {
    Alias proc (wrapper) for ad_return_template
} {
    uplevel 1 "ad_return_template $file_stub"
}

