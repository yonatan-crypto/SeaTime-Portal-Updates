@isTest
public class SubCustomerSailingTest {

    public static testMethod void insertMethod(){
        try{
        Account ac=new Account();
        ac.Name='Test Account';
        ac.Phone='1234567890';
        ac.Email__c='abc@gmail.com';
      
      
        insert ac;
        system.debug('accountid:::'+ac.id);
        Transaction__c transactionInstance=new Transaction__c();
        transactionInstance.Name='Test Transatcion';
        transactionInstance.Start_Date__c=Date.today();
        transactionInstance.End_Date__c=Date.today()+1;
        transactionInstance.Account_Name__c=ac.Id;
        transactionInstance.Date_of_Transaction__c=Date.today();
        insert transactionInstance;
        system.debug('Transaction:::'+transactionInstance.Id);
            
         Boats__c boatInstance=new Boats__c();
         boatInstance.Name='Test Boat';
         boatInstance.Active__c=true;
         boatInstance.License_Number__c=234;
         boatInstance.Type__c='sailboat';
         boatInstance.Max_Passenger__c=40;
            insert boatInstance;
         
            Id RecordTypeIdSail = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName().get('Enriching').getRecordTypeId();
            system.debug('RecordTypeIdSail:::: '+RecordTypeIdSail);
        Cruise__c sailInstance=new Cruise__c();
        sailInstance.RecordTypeId=RecordTypeIdSail;   
        sailInstance.Transaction__c=transactionInstance.Id;
        sailInstance.Boat__c=boatInstance.Id;  
        sailInstance.Start_Date__c=date.today();
        sailInstance.End_Date__c=Date.today()+1;
        sailInstance.Status__c='Approved'; 
        sailInstance.SCCount__c=5;  
        insert sailInstance;
                    Id RecordTypeIdSailFriend = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName().get('Friends').getRecordTypeId();
        Cruise__c sailInstance2=new Cruise__c();
        sailInstance2.RecordTypeId=RecordTypeIdSailFriend;   
        sailInstance2.Transaction__c=transactionInstance.Id;
        sailInstance2.Boat__c=boatInstance.Id;  
        sailInstance2.Start_Date__c=date.today();
        sailInstance2.End_Date__c=Date.today()+1;
        sailInstance2.Status__c='Approved'; 
        sailInstance2.SCCount__c=5;  
        insert sailInstance2;
         system.debug('sailInstance2:::'+sailInstance2.Id);
        
         Cruise__c sailInstance3=new Cruise__c();
        sailInstance3.RecordTypeId=RecordTypeIdSailFriend;   
        sailInstance3.Transaction__c=transactionInstance.Id;
        sailInstance3.Boat__c=boatInstance.Id;  
        sailInstance3.Start_Date__c=date.today();
        sailInstance3.End_Date__c=Date.today()+1;
        sailInstance3.Status__c='Approved'; 
        sailInstance3.SCCount__c=5;  
        insert sailInstance3;
            system.debug('sailInstance3:::'+sailInstance3);
        
        List<Co_Cruise_Members__c> newSubCustomerList=new List<Co_Cruise_Members__c>();
        Co_Cruise_Members__c subCustomerInstance=new Co_Cruise_Members__c();
        subCustomerInstance.Account_Co__c=ac.Id;
        subCustomerInstance.Cruise__c=sailInstance.Id;
         newSubCustomerList.add(subCustomerInstance);    
            
             Co_Cruise_Members__c subCustomerInstance2=new Co_Cruise_Members__c();
        subCustomerInstance2.Account_Co__c=ac.Id;
        subCustomerInstance2.Cruise__c=sailInstance2.Id;
        newSubCustomerList.add(subCustomerInstance2);
        insert newSubCustomerList;
            subCustomerInstance2.Cruise__c=sailInstance3.Id;
            Update subCustomerInstance2;
            delete subCustomerInstance2;
            
        }catch(Exception e){
            system.debug('Message in Test Class::'+e.getMessage());
             system.debug('Line Number in Test Class::'+e.getLineNumber());
        }
    }
    
    public static testMethod void findProfileTest(){
        /*List<Profile> profiles = [SELECT Id FROM Profile WHERE Name='מנהל מערכת']; 
        User u = new User(Alias = 'Data', Email='Data@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = profiles.size() > 0 ? profiles[0].Id : null, 
            TimeZoneSidKey='America/Los_Angeles', UserName='Data@testorg.com');
        insert u;
        test.startTest();
        SubCustomerSailing.findProfile(u.id);
        test.stopTest();*/
    }
   
}