trigger DocomotionRequestTrigger on Docomotion_Request__e (after insert) {
    DocomotionRequestTriggerHandler.handleAfterInsert(Trigger.new);
}
