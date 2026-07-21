@isTest
public class CreateDiarySharedDocOnCharterInsert_Test {
    @isTest
    public static void CreateDiarySharedDocOnCharterInsertTestMethod(){
        charters__c charter = new charters__c();
        charter.charter_date__c = date.today();
        charter.yacht_type__c = 'מונו';
        charter.yacht_model__c = 'Beneteau';
        charter.yacht_length__c = 6;
        charter.cabins__c = 3;
        charter.WC__c = 6;
        charter.Agent__c = 'תום';
        insert charter;
    }
}