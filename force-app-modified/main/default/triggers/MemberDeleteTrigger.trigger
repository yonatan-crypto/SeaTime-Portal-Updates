/*trigger MemberDeleteTrigger on Co_Cruise_Members__c (before delete) {
    if (Trigger.isDelete)
        CruiseCancelled.beforeDelete(Trigger.old);
}*/

// commented by Bali Krishan 04/02/26

        // added Bali Krishan for error handling CANNOT_EXECUTE_FLOW_TRIGGER
trigger MemberDeleteTrigger on Co_Cruise_Members__c (after delete) {
    if (Trigger.isDelete)
        CruiseCancelled.afterDelete(Trigger.old);
}