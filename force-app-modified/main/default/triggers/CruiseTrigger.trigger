/*
 * @Author: ZedXagE 
 * @Date: 2019-04-23 11:10:12 
 * @Last Modified by: ZedXagE
 * @Last Modified time: 2019-04-23 11:40:21
 */

trigger CruiseTrigger on Cruise__c (before insert, before update ,before delete,after update, after insert) {
    CruiseHandler handler = new CruiseHandler();
	//before
    if (Trigger.isInsert&&Trigger.isBefore){ 
        handler.checkAccountHasCertificate(Trigger.new );
        handler.CalculateExtraHours(Trigger.new , new Set <String>());
      
    } 
    if (Trigger.isUpdate&&Trigger.isBefore){ 
        handler.checkAccountHasCertificate(Trigger.new );
        handler.CalculateExtraHours(Trigger.newMap, Trigger.oldMap );
    } 
    if(Trigger.isUpdate&&Trigger.isAfter){
        String clubrectype = [select id from RecordType where Name = 'Club'
            and SobjectType = 'Cruise__c'
        ].id;
        Set <String> transchanged = new Set <String>();
        Set <String> ccmsids = new Set <String>();
        for(Cruise__c cc:Trigger.new){
            Cruise__c occ = Trigger.oldmap.get(cc.id);
            if(cc.RecordTypeid != clubrectype&&(cc.Start_Date__c!=occ.Start_Date__c||cc.End_Date__c!=occ.End_Date__c||cc.Status__c!=occ.Status__c||cc.Holiday__c!=occ.Holiday__c||cc.Transaction__c!=occ.Transaction__c))
                ccmsids.add(cc.id);
        }
        List <Co_Cruise_Members__c> ccms = [select id,Transaction__c from Co_Cruise_Members__c where Cruise__c in: ccmsids];
        Database.update(ccms,false);
        for(Co_Cruise_Members__c ccm:ccms)
            transchanged.add(ccm.Transaction__c);
        if(transchanged.size()>0)   ID jobID = System.enqueueJob(new TransactionPoints(transchanged));
    }
    //handle delete points
    if (Trigger.isDelete&&Trigger.isBefore){
        handler.upOldVals(Trigger.Old);
    }
    // Handle to update Co Cruise Members noOfSCCountsForSelectedMonth - created by Sameer- 15th Dec 2021
   if(Trigger.isUpdate && Trigger.isAfter){
        handler.updateNumberOfCount(trigger.new, trigger.oldmap);
       // handler.updateAvailableSeatsInboat(trigger.new, trigger.oldmap); 
    }
    // Handle to update the available seats in boat - created by Sameer- 15th Dec 2021
    if(Trigger.isInsert && Trigger.isAfter){
        // handler.updateAvailableSeatsInboat(Trigger.new);
    }
}