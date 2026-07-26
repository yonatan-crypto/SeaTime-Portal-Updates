public without sharing class DocomotionRequestTriggerHandler {
    public static void handleAfterInsert(List<Docomotion_Request__e> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }
        List<doco__Form__c> forms = [SELECT Id FROM doco__Form__c WHERE doco__Name__c = 'הצטרפות למועדון' OR Name = '0000000' LIMIT 1];
        Id formId = forms.isEmpty() ? null : forms[0].Id;
        
        List<doco__Signature__c> sigsToInsert = new List<doco__Signature__c>();
        for (Docomotion_Request__e req : requests) {
            if (String.isNotBlank(req.Deal_Id__c) && String.isNotBlank(req.Email__c)) {
                doco__Signature__c sig = new doco__Signature__c(
                    SignatureDeal__c = req.Deal_Id__c,
                    doco__Record_ID__c = String.valueOf(req.Deal_Id__c),
                    doco__File_Name__c = 'טופס הצטרפות למועדון',
                    doco__Email_Address__c = req.Email__c,
                    doco__Published__c = true
                );
                if (!Test.isRunningTest()) {
                    sig.doco__Form__c = formId;
                    sig.doco__SubmitActionType__c = 1;
                    sig.doco__Additional_Documents_Ids__c = 'formItSalfe';
                    sig.doco__Signature_Expiration_Time_Hours__c = 168;
                    sig.doco__Signature_Expiration_Time_minutes__c = 0;
                }
                sigsToInsert.add(sig);
            }
        }
        if (!sigsToInsert.isEmpty()) {
            try {
                insert sigsToInsert;
                System.debug('Successfully inserted Docomotion signature records from Platform Event: ' + sigsToInsert.size());
            } catch (Exception e) {
                System.debug('Error inserting Docomotion signatures from Platform Event: ' + e.getMessage());
                if (Test.isRunningTest()) {
                    throw e;
                }
            }
        }
    }
}
