ad_library {
    Installation procs for authentication, account management, and password management,

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-05-13
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::authentication {}
namespace eval auth::password {}
namespace eval auth::registration {}


ad_proc -private auth::package_install {} {} {

    db_transaction {
        # Create service contracts
        auth::authentication::create_contract
        auth::password::create_contract
        auth::registration::create_contract
        
        # Register local authentication implementations and update the local authority
        auth::local::install
    }
}

ad_proc -private auth::package_uninstall {} {} {

    db_transaction {

        # Unregister local authentication implementations and update the local authority
        auth::local::uninstall

        # Delete service contracts
        auth::authentication::delete_contract
        auth::password::delete_contract
        auth::registration::delete_contract
    }
}


#####
#
# auth_authentication service contract
#
#####

ad_proc -private auth::authentication::create_contract {} {
    Create service contract for authentication.
} {
    set spec {
        name "auth_authentication"
        description "Service contract to handle authentication"
        operations {
            Authenticate {
                description {
                    Validate this username/password combination, and return the result.
                    Valid auth_status codes are 'ok', 'no_account', 'bad_password', 'auth_error', 'failed_to_connect'. 
                    The last, 'failed_to_connect', is reserved for communications or implementation errors.
                    Valid account_status codes are 'ok' and 'closed'.
                }
                input {
                    username:string
                    password:string
                    parameters:string,multiple
                }
                output {
                    auth_status:string
                    auth_message:string
                    account_status:string
                    account_message:string
                }
            }
            GetParameters {
                description {
                    Get an arraay-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec

    # LARS:
    # If we do the configurator package, this proc should register the parameters as well,
    # and GetParameters should return parameter_set_id.
    # Hm. But it'll be up to the specific implementation which parameters it takes ... yeah, above won't work.
}

ad_proc -private auth::authentication::delete_contract {} {
    Delet service contract for authentication.
} {
    acs_sc::contract::delete -name "auth_authentication"
}

#####
#
# auth_password service contract
#
#####

ad_proc -private auth::password::create_contract {} {
    Create service contract for password management.
} {
    set spec {
        name "auth_password"
        description "Service contract for password management."
        operations {
            CanChangePassword {
                description {
                    Return whether the user can change his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    changeable_p:boolean
                }
                iscachable_p "t"
            }
            ChangePassword {
                description {
                    Change the user's password. 
                }
                input {
                    username:string
                    old_password:string
                    new_password:string
                    parameters:string,multiple
                }
                output {
                    successful_p:boolean
                    message:string
                }
            }
            CanRetrievePassword {
                description {
                    Return whether the user can retrieve his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    retrievable_p:boolean
                }
                iscachable_p "t"
            }
            RetrievePassword {
                description {
                    Retrieve the user's password. The implementation can either return the password, in which case
                    the authentication API will email the password to the user. Or it can email the password
                    itself, in which case it would return the empty string for password.
                }
                input {
                    username:string
                    parameters:string,multiple
                }
                output {
                    successful_p:boolean
                    message:string
                    password:string
                }
            }
            CanResetPassword {
                description {
                    Return whether the user can reset his/her password through this implementation.
                    The value is not supposed to depend on the username and should be cachable.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    retrievable_p:boolean
                }
                iscachable_p "t"
            }
            ResetPassword {
                description {
                    Reset the user's password to a new, randomly generated value. 
                    The implementation can either return the password, in which case
                    the authentication API will email the password to the user. Or it can email the password
                    itself, in which case it would return the empty string.
                }
                input {
                    username:string
                    parameters:string,multiple
                }
                output {
                    successful_p:boolean
                    message:string
                    password:string
                }
            }
            GetParameters {
                description {
                    Get an arraay-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec
}

ad_proc -private auth::password::delete_contract {} {
    Delete service contract for password management.
} {
    acs_sc::contract::delete -name "auth_password"
}


#####
#
# auth_registration service contract
#
#####

ad_proc -private auth::registration::create_contract {} {
    Create service contract for account registration.
} {
    set spec {
        name "auth_registration"
        description "Service contract to handle account registration"
        operations {
            GetElements {
                description {
                    Get a list of required and a list of optional fields available when registering accounts through this
                    service contract implementation.
                }
                input {
                    parameters:string,multiple
                }
                output {
                    requiered:string,multiple
                    optional:string,multiple
                }
            }
            Register {
                description {
                    Register a new account. Valid status codes are: 'ok', 'data_error', and 'reg_error', and 'fail'.
                    'data_error' means that the implementation is returning an array-list of element-name, message 
                    with error messages for each individual element. 'reg_error' is any other registration error, 
                    and 'fail' is reserved to communications or implementation errors.
                }
                input {
                    parameters:string,multiple
                    username:string
                    authority_id:integer
                    first_names:string
                    last_name:string
                    email:string
                    url:string
                    password:string
                    secret_question:string
                    secret_answer:string
                }
                output {
                    creation_status:string
                    creation_message:string
                    element_messages:string,multiple
                    account_status:string
                    account_message:string
                }
            }
            GetParameters {
                description {
                    Get an array-list of the parameters required by this service contract implementation.
                }
                output {
                    parameters:string,multiple
                }
            }
        }
    }

    acs_sc::contract::new_from_spec -spec $spec

    # LARS:
    # If we do the configurator package, this proc should register the parameters as well,
    # and GetParameters should return parameter_set_id.
}


ad_proc -private auth::registration::delete_contract {} {
    Delete service contract for account registration.
} {
    acs_sc::contract::delete -name "auth_registration"
}
