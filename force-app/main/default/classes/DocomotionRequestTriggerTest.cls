@isTest
private class DocomotionRequestTriggerTest {
    @isTest
    static void testPlatformEventHandling() {
        Account acc = new Account(Name = 'Test Account for Event');
        insert acc;
        
        Transaction__c trans = new Transaction__c(
            Account__c = acc.Id,
            Status__c = 'פעילה',
            email_client_deal__c = 'test@example.com'
        );
        insert trans;
        
        Test.startTest();
        Docomotion_Request__e eventReq = new Docomotion_Request__e(
            Deal_Id__c = trans.Id,
            Email__c = 'test@example.com'
        );
        Database.SaveResult sr = EventBus.publish(eventReq);
        System.assert(sr.isSuccess(), 'Platform event should publish successfully');
        
        // Ensure direct execution of handler for deterministic unit test coverage
        DocomotionRequestTriggerHandler.handleAfterInsert(new List<Docomotion_Request__e>{ eventReq });
        Test.stopTest();
        
        List<doco__Signature__c> sigs = [SELECT Id, SignatureDeal__c, doco__Email_Address__c FROM doco__Signature__c WHERE SignatureDeal__c = :trans.Id];
        System.assert(!sigs.isEmpty(), 'Signature records should be inserted by handler');
        System.assertEquals('test@example.com', sigs[0].doco__Email_Address__c, 'Email should match requested address');
    }
}
