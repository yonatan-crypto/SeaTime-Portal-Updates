/*trigger CoCruiseTrigger on Co_Cruise_Members__c(
  before insert,
  before update,
  before delete
) {
  CoCruiseTriggerHandler.handleCoCruiseTrigger(Trigger.operationType);
}
*/
// commented by Bali Krishan 04/02/26

// new for error handling CANNOT_EXECUTE_FLOW_TRIGGER
trigger CoCruiseTrigger on Co_Cruise_Members__c(
  before insert,
  before update,
  before delete,
  after delete
) {
    CoCruiseTriggerHandler.handleCoCruiseTrigger(Trigger.operationType);
}