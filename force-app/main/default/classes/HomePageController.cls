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

        homePageDataToReturn.put('cruiseRecordsArray', cruiseRecordsArray);
        homePageDataToReturn.put('account', accountData);
        homePageDataToReturn.put('transaction', transactionData);

        return homePageDataToReturn;
    }
}