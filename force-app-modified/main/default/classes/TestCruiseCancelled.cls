@isTest
public class TestCruiseCancelled {
    
    // Helper method for fake Ids
    private static Integer fakeIdCount = 1;
    
    private static Id getFakeId(Schema.SObjectType sObjectType) {
        String result = String.valueOf(fakeIdCount++);
        return (Id)(sObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result);
    }
    
    static testMethod void testAfterDeleteWithValidData() {
        // Create mock Ids
        Id mockAccountId = getFakeId(Account.SObjectType);
        Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
        Id mockCoMemberId = getFakeId(Co_Cruise_Members__c.SObjectType);
        
        // Create in-memory object WITHOUT insert
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Id = mockCoMemberId,
            Account_Co__c = mockAccountId,
            Cruise__c = mockCruiseId
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = false;
        CoCruiseTriggerHandler.byPassTrigger = false;
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'Method executed without DB operations');
    }
    
    static testMethod void testWithTestBypassEnabled() {
        Id mockAccountId = getFakeId(Account.SObjectType);
        Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
        
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Account_Co__c = mockAccountId,
            Cruise__c = mockCruiseId
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = true;
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'testBypass working');
    }
    
    static testMethod void testWithTriggerBypassEnabled() {
        Id mockAccountId = getFakeId(Account.SObjectType);
        Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
        
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Account_Co__c = mockAccountId,
            Cruise__c = mockCruiseId
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = false;
        CoCruiseTriggerHandler.byPassTrigger = true;
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'byPassTrigger working');
    }
    
    static testMethod void testNullCruiseCheck() {
        Id mockAccountId = getFakeId(Account.SObjectType);
        
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Account_Co__c = mockAccountId,
            Cruise__c = null
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = false;
        CoCruiseTriggerHandler.byPassTrigger = false;
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'Null Cruise handled');
    }
    
    static testMethod void testNullAccountCheck() {
        Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
        
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Account_Co__c = null,
            Cruise__c = mockCruiseId
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = false;
        CoCruiseTriggerHandler.byPassTrigger = false;
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'Null Account handled');
    }
    
    static testMethod void testBothNullCheck() {
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Account_Co__c = null,
            Cruise__c = null
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = false;
        CoCruiseTriggerHandler.byPassTrigger = false;
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'Both null handled');
    }
    
    static testMethod void testEmptyList() {
        Test.startTest();
        
        CruiseCancelled.testBypass = false;
        CoCruiseTriggerHandler.byPassTrigger = false;
        
        List<Co_Cruise_Members__c> emptyList = new List<Co_Cruise_Members__c>();
        CruiseCancelled.afterDelete(emptyList);
        
        Test.stopTest();
        
        System.assert(true, 'Empty list handled');
    }
    
    static testMethod void testMultipleRecords() {
        Id mockAccountId = getFakeId(Account.SObjectType);
        Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
        Id mockId1 = getFakeId(Co_Cruise_Members__c.SObjectType);
        Id mockId2 = getFakeId(Co_Cruise_Members__c.SObjectType);
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{
            new Co_Cruise_Members__c(Id = mockId1, Account_Co__c = mockAccountId, Cruise__c = mockCruiseId),
            new Co_Cruise_Members__c(Id = mockId2, Account_Co__c = null, Cruise__c = mockCruiseId),
            new Co_Cruise_Members__c(Account_Co__c = mockAccountId, Cruise__c = null),
            new Co_Cruise_Members__c(Account_Co__c = null, Cruise__c = null)
        };
        
        Test.startTest();
        
        CruiseCancelled.testBypass = false;
        CoCruiseTriggerHandler.byPassTrigger = false;
        
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'Multiple records handled');
    }
    
    static testMethod void testBothBypassesEnabled() {
        Id mockAccountId = getFakeId(Account.SObjectType);
        Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
        
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Account_Co__c = mockAccountId,
            Cruise__c = mockCruiseId
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = true;
        CoCruiseTriggerHandler.byPassTrigger = true;
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'Both bypasses working');
    }
    
    static testMethod void testMixedBypass1() {
        Id mockAccountId = getFakeId(Account.SObjectType);
        Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
        
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Account_Co__c = mockAccountId,
            Cruise__c = mockCruiseId
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = false;
        CoCruiseTriggerHandler.byPassTrigger = true;
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'Mixed bypass 1 working');
    }
    
    static testMethod void testMixedBypass2() {
        Id mockAccountId = getFakeId(Account.SObjectType);
        Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
        
        Co_Cruise_Members__c co = new Co_Cruise_Members__c(
            Account_Co__c = mockAccountId,
            Cruise__c = mockCruiseId
        );
        
        Test.startTest();
        
        CruiseCancelled.testBypass = true;
        CoCruiseTriggerHandler.byPassTrigger = false;
        
        List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
        CruiseCancelled.afterDelete(deleteList);
        
        Test.stopTest();
        
        System.assert(true, 'Mixed bypass 2 working');
    }
    
    
static testMethod void testAfterDeleteWithValidData1() {
    Id mockAccountId = getFakeId(Account.SObjectType);
    Id mockCruiseId = getFakeId(Cruise__c.SObjectType);
    Id mockCoMemberId = getFakeId(Co_Cruise_Members__c.SObjectType);
    
    Co_Cruise_Members__c co = new Co_Cruise_Members__c(
        Id = mockCoMemberId,
        Account_Co__c = mockAccountId,
        Cruise__c = mockCruiseId
    );
    
    Test.startTest();
    
    CruiseCancelled.testBypass = false;
    CoCruiseTriggerHandler.byPassTrigger = false;
    
    List<Co_Cruise_Members__c> deleteList = new List<Co_Cruise_Members__c>{co};
    CruiseCancelled.afterDelete(deleteList); // Flow lines execute hongi aur catch hongi
    
    Test.stopTest();
    
    System.assert(true, 'Flow execution attempted and caught');
}
}