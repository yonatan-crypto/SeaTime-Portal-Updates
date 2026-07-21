@isTest
public class SailBookControllerTest {
    
    static testMethod void SailBookControllerTest1() 
    {
        Account testAccount = new Account();
        testAccount.Name='Test Account' ;
        insert testAccount;
        
        Test.StartTest(); 
        ApexPages.StandardController sc = new ApexPages.StandardController(testAccount);
        SailBookController testAccPlan = new SailBookController();
        
        PageReference pageRef = Page.SeatimeSchedulerBooking; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(testAccount.Id));
        Test.setCurrentPage(pageRef);
        
       SailBookController.accountId=testAccount.id;
        Test.StopTest();
    }
}