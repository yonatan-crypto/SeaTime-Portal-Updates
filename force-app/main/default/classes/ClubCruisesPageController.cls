/**
 * @description
 * @author Ceptes
 * @date Friday-August-02-2024
 **/

public without sharing class ClubCruisesPageController {
    
    static SeaTimeAppSelector selector = new SeaTimeAppSelector();

    @AuraEnabled
    public static PriceListLine__c[] getClubCruisePrices(String boatIdsArray) {

        return selector.getPriceListLinesFromBoatIds(boatIdsArray);
    }

    @AuraEnabled
    public static boolean createCoCruiseMember(Map<string, object> selectedCruise) {

        id cruiseId  = (id) selectedCruise.get('id');
        id accountId = (id) selectedCruise.get('accountId');

        Transaction__c transactionRec  = selector.getTransactionFromAccount(accountId);
        Cruise__c cruiseRecord              = selector.getCruiseRecord(cruiseId); 

        // Check if user is a student (StudentMeshit30)
        List<Account> accounts = [SELECT Id, StudentMeshit30__c FROM Account WHERE Id = :accountId LIMIT 1];
        Boolean isStudent = !accounts.isEmpty() && accounts[0].StudentMeshit30__c == true;

        // For non-students, require a valid transaction. Students can book without one.
        if (!isStudent && transactionRec.Id == null) { return false; }
        
        // Always check remaining seats
        if (cruiseRecord.RemaingSeatsInBoat__c <= 0) { return false; }
        
        Co_Cruise_Members__c coCruiseMember = new Co_Cruise_Members__c();
        coCruiseMember.Cruise__c            = cruiseId;
        coCruiseMember.Transaction__c       = transactionRec.Id; // null for students without subscription
        coCruiseMember.Account_Co__c        = accountId;
        insert coCruiseMember;
        return true;
    }
}