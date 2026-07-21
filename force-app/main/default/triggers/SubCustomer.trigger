trigger SubCustomer on Co_Cruise_Members__c (after insert,after update, before delete) {
    if(trigger.isafter && trigger.isInsert){
        SubCustomerSailing.insertMethod(trigger.new);
    }
    if(trigger.isAfter && trigger.isUpdate){
        SubCustomerSailing.updateMethod(trigger.oldMap,trigger.newMap);
    }
    if(trigger.isbefore && trigger.isDelete){
        SubCustomerSailing.deleteMethod(trigger.old);
    }
    
}