<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="notification::delete.delete_notification">
        <querytext>
            declare begin
                notification.delete(:notification_id);
            end;
        </querytext>
    </fullquery>

    <fullquery name="notification::mark_sent.insert_notification_user_map">
        <querytext>
            insert
            into notification_user_map
            (notification_id, user_id, sent_date)
            select :notification_id, :user_id, sysdate
            from dual where exists (select 1 from notifications
                                    where notification_id = :notification_id)
        </querytext>
    </fullquery>


</queryset>
