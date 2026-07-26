/**
 * @description
 * @author Ceptes
 * @date Wednesday-August-14-2024
 **/

 @isTest
public class SeaTimeAppTest {

    @TestSetup
    static void createSeaTimeAppTestData() {
        
        Account accountData  = new Account();
        accountData.Name     = 'Test Account'; 
        accountData.Phone    = '123456'; 
        accountData.Email__c = 'gs650x@gmail.com';
        accountData.code__c  = '1234';
        insert accountData;

        Boats__c boat  = new Boats__c();
        boat.Name      = 'boat 1';
        boat.Type__c   = 'Yacht';
        boat.Active__c = true;
        insert boat;

        Transaction__c transactionData  = new Transaction__c();
        transactionData.Total_Points__c = 3000;
        transactionData.Account_Name__c = accountData.Id;
        transactionData.End_Date__c     = Date.today().addDays(1);
        transactionData.Date_of_Transaction__c = Date.today();
        transactionData.type_of_membership__c = 'חבר מועדון כולל פרטיות';
        insert transactionData;

        Certification__c certification    = new Certification__c();
        certification.Account_Name__c     = accountData.Id;
        certification.Boat__c             = boat.Id;
        certification.Date__c             = Date.today().addDays(1);
        certification.Expiration_Date__c  = Date.today().addDays(30);  
        certification.Boat__c             = boat.Id;
        insert certification;

        //Id clubRecordTypeId = Schema.SObjectType.Cruise__c.getRecordTypeInfosByName().get('Club').getRecordTypeId();

        Cruise__c cruise      = new Cruise__c();
        cruise.Boat__c        = boat.Id;
        cruise.recordTypeId   = '0120Y00000073ApQAI'/*clubRecordTypeId*/;
        cruise.Start_Date__c  = Date.Today().addDays(1);
        cruise.End_Date__c    = Date.Today().addDays(2);
        cruise.Transaction__c = transactionData.Id;
        cruise.Status__c      = 'Awaiting for Approval';
        cruise.AccountName__c = accountData.Id;
        cruise.SCCount__c     = 5;
        cruise.MaxParticipants__c  = 10;
        insert cruise;
        
        PriceList__c priceList = new PriceList__c(Name='בדיקה יונתן ',End_Date__c=Date.valueOf('2025-09-03'),Start_Date__c = Date.valueOf('2024-09-03') ,Type__c='רגיל',Price__c = 2);
        insert priceList;
        
         List<PriceListLine__c> priceLinelist = new List<PriceListLine__c>();
        Id boatId = getBoatId();
        
        priceLinelist.add(new PriceListLine__c(
            Price__c = 21.3,
            Boat__c = boatId,
            Type__c = 'Certification',
            PriceList__c = priceList.Id
        ));
        
        priceLinelist.add(new PriceListLine__c(
            Price__c = 21.3,
            Type__c = 'Enriching',
            PriceList__c = priceList.Id
        ));
        insert priceLinelist;
    }

    @isTest
    static void testLoginPage() {

        Map<String, string> userCredentials = new Map<String, string>{
            'userName' => 'gs650x@gmail.com',
            'password' => '123456'
        };

        Map<string, object> validCredsData = LoginPageAppController.isValidCredentials(userCredentials);

        Assert.isNotNull(validCredsData);

        id accountId = getAccountId();

        Map<string, object> validOtpData = LoginPageAppController.isValidOtp(accountId, '1234');

        Assert.isNotNull(validOtpData);
    }

    @isTest
    static void testHomePage() {

        id accountId = getAccountId();

        Map<string, object> homePageData = HomePageController.getHomePageTabsData(accountId);

        Assert.isNotNull(homePageData);
    }

    @isTest
    static void testPrivateReservationPage() {

        Map<String, object> searchData = new Map<String, object>{
            'boatTypes' => new List<string>{'Yacht'},
            'date' => String.valueOf(Date.today())
        };

        Map<String, object> privateReservationData = PrivateReservationPageController.getPrivateReservationData(searchData);

        Assert.isNotNull(privateReservationData);

        id accountId = getAccountId();
        id boatId    = getBoatId();

        Map<String, object> selectedBoat = new Map<String, object>{
            'startTime' => '10:12',
            'endTime' =>  '10:22',
            'date' => '2024-04-04',
            'boatId' => boatId,
            'accountId' => accountId
        };

        Id cruiseId = PrivateReservationPageController.createPrivateReservation(selectedBoat);

        Assert.isNotNull(cruiseId);

        Transaction__c trans = [SELECT Id FROM Transaction__c LIMIT 1];
        String result = PrivateReservationPageController.generateAndSendClubContract(trans.Id);
        Assert.areEqual('SUCCESS', result);
    }

    @isTest
    static void testClubCruisepage() {

        id boatId    = getBoatId();
        id accountId = getAccountId();
        id cruiseId  = getCruiseId();
        String startDate ='2024-09-03T07:00:00.000Z';

        List<PriceListLine__c> PriceListLineList = getPriceListLineList();
                                         
        List<Object> clubCruisesArray = (List<Object>)JSON.deserializeUntyped('[{"id":"' + cruiseId + '", "accountId": "' + accountId + '","recordTypeName":"Certification","boatId": "' + boatId + '","boatName":"Rosie","boatType":"Yacht","startDate":"' + startDate + '","endTime":"' + startDate + '"},{"id":"' + cruiseId + '", "accountId": "' + accountId + '","recordTypeName":"Enriching","boatId": "' + boatId + '","boatName":"Rosie","boatType":"Yacht","startDate":"' + startDate + '","endTime":"' + startDate + '"},{"id":"' + cruiseId + '", "accountId": "' + accountId + '","recordTypeName":"Enriching","boatId": "' + boatId + '","boatName":"Rosie","boatType":"Yacht","startDate":"' + startDate + '","endTime":"' + startDate + '"},{"id":"' + cruiseId + '","recordTypeName":"Course","boatId": "' + boatId + '","boatName":"Rosie","boatType":"Yacht","startDate":"' + startDate + '","endTime":"' + startDate + '"}]');

        ClubCruisesPageController.getClubCruisePrices(JSON.serialize(clubCruisesArray));

        Map<String, object> selectedCruise = new Map<String, object>{
            'id' => cruiseId,
            'accountId' => accountId
        };

        Boolean isCoCruiseMemberCreated = ClubCruisesPageController.createCoCruiseMember(selectedCruise);

        Assert.areEqual(true, isCoCruiseMemberCreated);
    }

    static Id getCruiseId() {
        return [SELECT id FROM Cruise__c LIMIT 1]?.Id;
    }

    static Id getAccountId() {
        return [SELECT id FROM Account LIMIT 1]?.Id;
    }

    static Id getBoatId() {
        return [SELECT id FROM Boats__c LIMIT 1]?.Id;
    }
    
    static List<PriceListLine__c> getPriceListLineList() {
        return [SELECT id, Price__c, Start__c,Type__c, Boat__c,
                                             PriceList__r.Start_Date__c,PriceList__r.End_Date__c FROM 
                                             PriceListLine__c WHERE Type__c != 'Club' AND PriceList__r.Start_Date__c <=: Date.valueOf('2024-09-03') AND
                                             PriceList__r.End_Date__c >=: Date.valueOf('2024-09-03') ORDER BY PriceList__r.CreatedDate];
    }
}