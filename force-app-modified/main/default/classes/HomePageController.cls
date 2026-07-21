/**
 * @description Apex controller class for Home page.
 * @author Ceptes
 * @date Tuesday-July-09-2024
 **/

public without sharing class HomePageController {

    static SeaTimeAppSelector selector = new SeaTimeAppSelector();
   
    @AuraEnabled
    public static Map<string, object> getHomePageTabsData(id accountId) {

        Transaction__c transactionData;
        Map<String, Object> homePageDataToReturn = new Map<String, Object>();

        Cruise__c[] cruiseRecordsArray    = selector.getRecentCruiseRecords(accountId);
        Account accountData               = selector.getAccountFromId(accountId);
        Transaction__c transactionRec = selector.getTransactionFromAccount(accountId);
        transactionData = transactionRec.Id != null ? transactionRec : null;

        List<PastSailing> pastClubCruises = getPastSailings(accountId, false);
        
        homePageDataToReturn.put('cruiseRecordsArray', cruiseRecordsArray);
        homePageDataToReturn.put('pastClubCruises', pastClubCruises);
        homePageDataToReturn.put('account', accountData);
        homePageDataToReturn.put('transaction', transactionData);

        return homePageDataToReturn;
    }

    @AuraEnabled
    public static List<PastSailing> getPastSailings(Id accountId, Boolean allPast) {
        List<PastSailing> results = new List<PastSailing>();

        Account acc = selector.getAccountFromId(accountId);
        Transaction__c trans = selector.getTransactionFromAccount(accountId);
        Boolean isStudent = acc != null && acc.StudentMeshit30__c == true;
        Id activeTransId = (trans != null && trans.Id != null && trans.Active__c) ? trans.Id : null;

        // 1. Private Cruises (RecordType = Club, AccountName__c = accountId)
        String privateQuery = 'SELECT Id, Boat__r.Name, Start_Date__c, End_Date__c, Additional_Info__c, Status__c, Transaction__c FROM Cruise__c WHERE AccountName__c = :accountId AND RecordType.Name = \'Club\' AND Status__c != \'Canceled\' AND Start_Date__c < TODAY';
        if (!allPast && activeTransId != null) {
            privateQuery += ' AND Transaction__c = :activeTransId';
        }
        List<Cruise__c> privateCruises = Database.query(privateQuery);
        for (Cruise__c c : privateCruises) {
            PastSailing ps = new PastSailing();
            ps.Id = c.Id;
            ps.boatName = c.Boat__r != null ? c.Boat__r.Name : '';
            ps.startDate = c.Start_Date__c;
            ps.endDate = c.End_Date__c;
            ps.additionalInfo = c.Additional_Info__c;
            ps.status = c.Status__c;
            ps.sailingType = 'Private';
            results.add(ps);
        }

        // 2. Guided Cruises (Co_Cruise_Members__c)
        String guidedQuery = 'SELECT Id, Cruise__r.Boat__r.Name, Cruise__r.Start_Date__c, Cruise__r.End_Date__c, Cruise__r.Additional_Info__c, Status__c, Transaction__c, SailType__c FROM Co_Cruise_Members__c WHERE Account_Co__c = :accountId AND Status__c != \'Canceled\' AND Cruise__r.Status__c != \'Canceled\' AND Cruise__r.Start_Date__c < TODAY';
        if (!allPast && activeTransId != null && !isStudent) {
            guidedQuery += ' AND Transaction__c = :activeTransId';
        }
        List<Co_Cruise_Members__c> guidedCruises = Database.query(guidedQuery);
        for (Co_Cruise_Members__c ccm : guidedCruises) {
            PastSailing ps = new PastSailing();
            ps.Id = ccm.Id;
            ps.boatName = ccm.Cruise__r != null && ccm.Cruise__r.Boat__r != null ? ccm.Cruise__r.Boat__r.Name : '';
            ps.startDate = ccm.Cruise__r != null ? ccm.Cruise__r.Start_Date__c : null;
            ps.endDate = ccm.Cruise__r != null ? ccm.Cruise__r.End_Date__c : null;
            ps.additionalInfo = ccm.Cruise__r != null ? ccm.Cruise__r.Additional_Info__c : '';
            ps.status = ccm.Status__c;
            ps.sailingType = 'Guided';
            results.add(ps);
        }

        results.sort();
        return results;
    }

    public class PastSailing implements Comparable {
        @AuraEnabled public Id Id {get;set;}
        @AuraEnabled public String boatName {get;set;}
        @AuraEnabled public DateTime startDate {get;set;}
        @AuraEnabled public DateTime endDate {get;set;}
        @AuraEnabled public String additionalInfo {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String sailingType {get;set;}

        public Integer compareTo(Object compareTo) {
            PastSailing compareToSailing = (PastSailing)compareTo;
            if (this.startDate == null || compareToSailing.startDate == null) return 0;
            if (this.startDate == compareToSailing.startDate) return 0;
            if (this.startDate > compareToSailing.startDate) return -1;
            return 1;
        }
    }
}