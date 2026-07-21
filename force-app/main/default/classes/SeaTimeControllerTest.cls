/**
 * @description App controller subscription page
 * @author Ceptes
 * @date Thursday-July-04-2024
 **/


@isTest
public class SeaTimeControllerTest {
    
    @TestSetup
    static void createSeaTimeAppTestData() {
        account acc = new account(Name='Account record', phone='1234',Email__c='Account@gmail.com');
        insert acc;
        
        Transaction__c sub = new Transaction__c(Name='Boat',Account_Name__c=acc.Id,
                                                         Date_of_Transaction__c=system.today(),Start_Date__c=system.today(),
                                                         End_Date__c=system.today(), type_of_membership__c = 'חבר מועדון כולל פרטיות');
        insert sub;
        Boats__c boat = new Boats__c(Name='Rosie',License_Number__c = 123,Max_Passenger__c=10);
        insert boat;
        Cruise__c cruise = new Cruise__c( Transaction__c=sub.Id,Boat__c	= boat.Id, Start_Date__c=system.today(),End_Date__c=system.today(),AccountName__c=acc.Id,status__c='For Payment',Holiday__c = true);
        insert cruise;
        List<PriceList__c> priceListRecList = new List<PriceList__c>();
        PriceList__c priceListRec = new PriceList__c(Type__c = 'רגיל',Start_Date__c=system.today(),End_Date__c = system.today(),Price__c=2.00);
        PriceList__c priceListRec1 = new PriceList__c(Type__c = 'מבצע',Start_Date__c=system.today(),End_Date__c = system.today(),Price__c=2.00);
        priceListRecList.add(priceListRec);
        priceListRecList.add(priceListRec1);
        insert priceListRecList;
         List<PriceListLine__c> priceListLineList = new List<PriceListLine__c>();   
        PriceListLine__c plLineRec = new PriceListLine__c(Start__c = Time.newInstance(20, 20, 20, 20),PriceList__c= priceListRecList[0].Id,Type__c='Club',Boat__c = boat.Id,Price__c=20,HPrice__c=200,Global__c = false);
        PriceListLine__c plLineRec2 = new PriceListLine__c(Start__c = Time.newInstance(10, 10, 10, 10),PriceList__c= priceListRecList[1].Id,Type__c='Club',Boat__c = boat.Id,Price__c=20,HPrice__c=200,Global__c = false);
		priceListLineList.add(plLineRec);
        priceListLineList.add(plLineRec2);
        insert priceListLineList;
        //Co_Cruise_Members__c cmember = new Co_Cruise_Members__c(Cruise__c=cruise.Id,Transaction__c=sub.Id,Account_Co__c=acc.Id);
    }
	@isTest
    public static void getSubscriptionDetailsTest(){
       account acc = [Select id,name,phone,Email__c from account limit 1];
       Cruise__c cruise = [Select id,Transaction__c,Boat__c,Start_Date__c,End_Date__c,AccountName__c,status__c from Cruise__c limit 1];
        Test.startTest();
        SeaTimeController.getSubscriptionDetails(String.valueOf(acc.Id));
        try{
        SeaTimeController.updateCruiseStatus(cruise.Id);
        SeaTimeController.updateCruiseStatus('');
        PrivateReservationPageController.getTransactionFromAccount(acc.Id);
        }catch(exception e){
            system.debug(e.getMessage());
        }
        Test.stopTest();
    }
   @isTest
    public static void calculateCruisePriceTest(){
       List<Cruise__c> cruiseList = [Select id,Transaction__c,Boat__c,Start_Date__c,End_Date__c,AccountName__c,status__c,Holiday__c from Cruise__c ];
       List<PriceListLine__c> priceListLineRec = [select id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c from PriceListLine__c];
		List < PriceList__c > dispricelists = [select id, Type__c, Start_Date__c, End_Date__c, Price__c, (select id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c from PriceListLines__r
                                                                                                          Order by Start__c) from PriceList__c Where Type__c = 'מבצע'
                                               Order by Start_Date__c DESC];

        Test.startTest();
        for(Cruise__c cr:cruiseList){
			SeaTimeController.calculateCruisePrice(cr);            
        }
        
        Test.stopTest();
    }
    @isTest
    public static void calculateCruisePriceTest2(){
        Cruise__c cruise = [Select id,Transaction__c,Boat__c,Start_Date__c,End_Date__c,AccountName__c,status__c,Holiday__c from Cruise__c limit 1];
        List<PriceListLine__c> priceListLineRec = [select id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c from PriceListLine__c];
        for(PriceListLine__c plLine:priceListLineRec){
            plLine.Boat__c = null;
        }

        update priceListLineRec;
        List < PriceList__c > regpricelists = [select id, Type__c, Start_Date__c, End_Date__c, Price__c, (select id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c from PriceListLines__r
                                                                                                          Order by Start__c) from PriceList__c Where Type__c = 'רגיל'
                                               Order by Start_Date__c DESC
                                              ];
        Test.startTest();
        SeaTimeController.calculateCruisePrice(cruise);
        Test.stopTest();
    }

    @isTest
    public static void cancelCoCruiseMemberTest() {
        Transaction__c sub = [SELECT Id FROM Transaction__c LIMIT 1];
        account acc = [SELECT Id FROM account LIMIT 1];
        Boats__c boat = [SELECT Id FROM Boats__c LIMIT 1];

        Cruise__c cruise = new Cruise__c(Transaction__c=sub.Id, Boat__c=boat.Id, Start_Date__c=System.today().addDays(5), End_Date__c=System.today().addDays(5), AccountName__c=acc.Id, status__c='Approved');
        insert cruise;

        Co_Cruise_Members__c member = new Co_Cruise_Members__c(Cruise__c=cruise.Id, Transaction__c=sub.Id, Account_Co__c=acc.Id);
        insert member;

        Test.startTest();
        SeaTimeController.cancelCoCruiseMember(member.Id);
        Test.stopTest();
    }

    @isTest
    public static void cancelCoCruiseSailresTest() {
        Transaction__c sub = [SELECT Id FROM Transaction__c LIMIT 1];
        account acc = [SELECT Id FROM account LIMIT 1];
        Cruise__c cruise = [SELECT Id FROM Cruise__c LIMIT 1];
        cruise.Start_Date__c = System.today().addDays(5);
        update cruise;

        Co_Cruise_Members__c sailres = new Co_Cruise_Members__c(Cruise__c=cruise.Id, Transaction__c=sub.Id, Account_Co__c=acc.Id);
        insert sailres;

        Test.startTest();
        SeaTimeController.cancelCoCruiseSailres(sailres.Id);
        Test.stopTest();
    }
}