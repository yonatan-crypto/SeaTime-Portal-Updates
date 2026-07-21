/**
* @desc Single Page Application Controller
* @class SeatimeSchedulerWebappController
* @author Niko, Ben
* @date OCT 2017
*/
global without sharing class SeatimeSchedulerWebappController {
    //private members
    private transient static final String STATUS_OK = 'Success';
    private transient static final String DESC_OK = 'SObject record was successfully updated';
    private transient static final String STATUS_ERROR = 'Process Failed';
    private transient static final String DESC_ERROR = 'Something went wrong, please update your system admin and add the error message';
    private transient static final String STATUS_ERROR_NEGATIVE = 'Negative Time Error';
    private transient static final String STATUS_ERROR_ROUND = 'Time Not Round Error';
    private transient static final Integer QUERY_LIMIT_CONDITION = 6000;
    private transient final static Integer NUM_OF_DAYS = 1; 
    private final static String AUTH_COOKIE_NAME = 'seatimeAccountCookie';
    private static final String POTENTIAL_DEAL = 'Potential Deal';
    private static final String SUBSCRIPTION_RECORD_TYPE_DEV_NAME = 'Subscription';
    private static final String NO_DEAL_TYPE = 'No Deal';
    private static transient Translator translator;
    private String schedulerMdtStatusSetting;
    
    //global members
    global Boolean isSandbox {get{ return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox; } private set;}
    global String currentUserLocale {get{return UserInfo.getLocale();} private set;}
    global String currentUserType {get {return UserInfo.getUserType();} private set;}
    global static String appTranslations {get{return JSON.serialize(translator.translationsMap);} private set;}
    
    //employee appliaction state constants getters
    global String orgBoats {get{ return SeatimeAuthenticationService.isStandardUser() ? JSON.serialize(getOrgBoats()) : null; } private set;}
    global String orgAccounts {get{ return SeatimeAuthenticationService.isStandardUser() ? JSON.serialize(getOrgAccounts()) : null ; } private set;} 
    global String orgCruiseRecordTypes {get{ return SeatimeAuthenticationService.isStandardUser() ? JSON.serialize(getCruiseOrgRecordTypes()) : null ; } private set;} 
    global String orgEmployees {get{ return SeatimeAuthenticationService.isStandardUser() ? JSON.serialize(getOrgEmployees()) : null ; } private set;} 

    global SeatimeSchedulerWebappController(){
        translator = new Translator();
        translator.addDictrionary('BoatType','Boats__c','Type__c');
        translator.addDictrionary('CruiseStatus','Cruise__c','Status__c');
    } //constructor:default

    global String getSchedulerMdtStatusSetting(){
        Map<String,Scheduler_Color_Setting__mdt> masterLabelToColorSettingMdtMap = new Map<String,Scheduler_Color_Setting__mdt>();
        Map<Id,Scheduler_Color_Setting__mdt> colorSettingMdtMap =new Map<Id,Scheduler_Color_Setting__mdt>(
            [SELECT Id, 
                    DeveloperName, 
                    MasterLabel, 
                    Language, 
                    Label,
                    Color__c, 
                    Color_Name__c, 
                    Heb_Label__c 
            FROM Scheduler_Color_Setting__mdt]
        );
        for(Scheduler_Color_Setting__mdt statusMdtItem : colorSettingMdtMap.values()){
            masterLabelToColorSettingMdtMap.put(statusMdtItem.MasterLabel,statusMdtItem);
        }
        return JSON.serialize(masterLabelToColorSettingMdtMap);
    }//method:getter:mdt


    //employee appliaction state getters methods

    /**
    * @desc org record types developername to recordtype map
    * @method getOrgRecordTypes
    * @return Map<String,RecordType> 
    */
    private static Map<String,RecordType> getCruiseOrgRecordTypes(){
        if(SeatimeAuthenticationService.isStandardUser()){
            Map<String,RecordType> orgDevNameToRecordTypeMap = new Map<String,RecordType>();
            Map<Id,RecordType> orgRecordTypeMap = getCruiseRecordTypeMap();

            for(RecordType recordTypeItem : orgRecordTypeMap.values()){
                orgDevNameToRecordTypeMap.put(recordTypeItem.DeveloperName,recordTypeItem);
            }
            return orgDevNameToRecordTypeMap;
        } 
        return new Map<String,RecordType>();
    }//method:query 

    /**
    * @desc org employees
    * @method getOrgEmployees
    * @return Map<Id,Employee__c> 
    */
    private static Map<Id,Employee__c> getOrgEmployees(){
        if(SeatimeAuthenticationService.isStandardUser()){
            return new Map<Id,Employee__c> (
                [SELECT Id,
                        Name
                 FROM Employee__c
                 LIMIT 10000]);
        } 
        return new Map<Id,Employee__c>();
    }//method:query 

    /**
    * @desc org boats
    * @method getOrgBoats
    * @return Map<Id,Boats__c> 
    */
    @TestVisible
    private static Map<Id,Boats__c> getOrgBoats(){
        if(SeatimeAuthenticationService.isStandardUser()){
            return new Map<Id,Boats__c> (
                [SELECT Id,
                       Name,
                       Boat_Id__c,
                       License_Number__c,
                       Type__c,
                       Max_Passenger__c,
                       Active__c,
                       Docking__c,
                       Convertion__c,
                       License_Expiration_Date__c,
                       Pyrotechnics_Experation_Date__c
                FROM Boats__c
                ORDER BY Docking__c ASC, Type__c ASC]);
        } 
        return new Map<Id,Boats__c>();
    }//method:query

    /**
    * @desc org accounts
    * @method getOrgAccounts
    * @return Map<Id,Account>
    */
    @TestVisible
    private static Map<Id,Account> getOrgAccounts(){
        if(SeatimeAuthenticationService.isStandardUser()){
            return new Map<Id,Account> (
                [SELECT Id,
                        Name
                FROM Account 
                WHERE Id IN (SELECT Account_Name__c FROM Transaction__c)
                LIMIT : QUERY_LIMIT_CONDITION]);
        }
        return new Map<Id,Account>();
    }//method:query

    /**
    * @desc org cruises
    * @method getOrgCruises
    * @return Map<Id,Cruise__c> 
    */
    @RemoteAction 
    global static Map<Id,Cruise__c> getOrgCruises(){
        final String CANCELED = 'Canceled';
        final Date FIRST_DAY_OF_CURRENT_MONTH = Date.today().toStartOfMonth();
        if(SeatimeAuthenticationService.isStandardUser()){
            return new Map<Id,Cruise__c>([
                SELECT Id, 
                       Name, 
                       RecordTypeId,
                       toLabel(RecordType.Name),
                       RecordType.DeveloperName,
                       Start_Date__c, 
                       End_Date__c, 
                       AccountName__c, 
                       AccountName__r.Name,
                       Guide__c, 
                       Guide__r.Name,
                       Transaction__c, 
                       Boat__c, 
                       Boat_Name__c,
                       Type__c, 
                       Status__c, 
                       Subject__c, 
                       Co_Cruise__c,
                       Payment_Required__c, 
                       Payment_Required_Image__c,
                       Additional_Info__c,
                       Holiday__c
                FROM Cruise__c
                WHERE (Start_Date__c > : FIRST_DAY_OF_CURRENT_MONTH OR Start_Date__c = LAST_N_DAYS:31)
                AND Status__c !=: CANCELED
                ORDER BY CreatedDate ASC]);
        } 
        return new Map<Id,Cruise__c>();
    }//method:remoting:query    

    /**
    * @desc org cruises
    * @method getOrgCruises
    * @return Map<Id,Cruise__c> 
    */
    @RemoteAction 
    global static Map<String, List<Event>> getEmployeeClassroomEvents(){
        SchedulerService schedulerSevice = new SchedulerService();
        return schedulerSevice.getEmployeeClassroomEvents();
    }//method:remoting:query    


    //account appliaction state getters methods

    /**
    * @desc secured account getter
    * @method getSecureAccount
    * @param securityToken (String)
    * @return SecureAccount
    */
    @RemoteAction 
    global static SecureAccount getSecureAccount(String securityToken){
        Account tokenziedAccount = SeatimeAuthenticationService.getSecuredAccountByToken(securityToken);
        SecureAccount secureAccount = new SecureAccount(securityToken,tokenziedAccount);
        return secureAccount;
    }//method:remoting:query

    /**
    * @desc account boat map getter
    * @method getAccountBoats
    * @param SecureAccount
    * @return Map<Id,Boats__c>
    */
    @RemoteAction
    global static Map<Id,Boats__c> getAccountBoats(SecureAccount secureAccount){
        Id accountId = secureAccount.tokenizedAccount.Id;
        return getAccountBoats(accountId);
    }//method:remoting:query    

    /**
    * @desc Account boats
    * @method getAccountBoats
    * @param String
    * @return Map<Id,Boats__c>
    */
    private static Map<Id,Boats__c> getAccountBoats(String accountId){
        Set<String> boatNameSet = new Set<String>();
        List<Certification__c> certificationList = [
            SELECT Id, 
                   Boat__r.Name, 
                   Account_Name__c
            FROM Certification__c
            WHERE Account_Name__c =: accountId];

        for(Certification__c certificationItem : certificationList) {
            boatNameSet.add(certificationItem.Boat__r.Name);
        }
        Map<Id,Boats__c> idBoatsObjMap = new Map<Id,Boats__c>([
            SELECT Id, 
                    Name, 
                    Type__c
            FROM Boats__c
            WHERE Name IN: boatNameSet And Active__c=true
            ORDER BY Type__c]);
        return idBoatsObjMap;
    }//method:overload:query

    /**
    * @desc prepare scheduler
    * @method getCruisesForScheduler
    * @param 
    * @return 
    */
    @RemoteAction
    global static List<Cruise__c> getCruisesForScheduler(SecureAccount secureAccount, Date selectedDate){
        Id accountId = secureAccount.tokenizedAccount.Id;
        SchedulerService service = new SchedulerService(
            accountId, 
            NUM_OF_DAYS, 
            getAccountBoats(accountId),
            selectedDate
        );
        List<Cruise__c> accountCruises = service.prepareScheduler();
        return accountCruises;
    }//method:remoting:query

    /**
    * @desc cruises history getter
    * @method getCruiseHistory
    * @param 
    * @return 
    */
    @RemoteAction
    global static List<Cruise__c> getCruiseHistory(SecureAccount secureAccount){
        Id accountId = secureAccount.tokenizedAccount.Id;
        if(String.isNotBlank(accountId)){
            return [SELECT Id, 
                        Name, 
                        Type2__c, 
                        Boat__r.Name, 
                        Guide__r.Name, 
                        toLabel(Status__c),
                        Hidden_Total_Hours__c, 
                        Active_Total_Hours__c, // FIX-2018-07-19 - add another col to history table
                        Start_Date__c, 
                        End_Date__c, 
                        AccountName__c,
                        CreatedDate,
                        Cruise_Points__c
                FROM Cruise__c
                WHERE AccountName__c =: accountId
                ORDER BY CreatedDate DESC
                LIMIT 15];
        }
        return new List<Cruise__c>();
    }//method:remoting:query

    /**
    * @desc account personal details getter
    * @method getPersonalDetails
    * @param 
    * @return 
    */
    @RemoteAction
    global static String getPersonalDetails(SecureAccount secureAccount){
        Id accountId = secureAccount.tokenizedAccount.Id;
        //Schema.DescribeSObjectResult transactionSobjectType = Schema.SObjectType.Transaction__c;
        //Id subscriptionRecordTypeId = transactionSobjectType.getRecordTypeInfosByName().get('Subscription').getRecordTypeId(); //schema returns hebrew keys
        RecordType clubRecordType = [SELECT Id,Name,DeveloperName FROM RecordType WHERE DeveloperName =: SUBSCRIPTION_RECORD_TYPE_DEV_NAME LIMIT 1];
        RecordType ptsRecordType = [SELECT Id,Name,DeveloperName FROM RecordType WHERE DeveloperName =: 'Points' LIMIT 1];
        if(String.isNotBlank(accountId) && clubRecordType != null){
            return JSON.serialize(
                [SELECT
                    Id,
                    Name,
                    Email__c,
                    Description,
                    Interest__c,
                    Phone,
                    Time_Passed_From_Last_Sailing__c,
                    (SELECT
                        Id,
                        Transaction_Number__c,
                        Total_Used_Hours__c,
                        Remaining_hours__c,
                        Type__c,
                        Name,
                        Used_Points__c,
                        Points_Balance__c,
                        RecordType.Name
                    FROM Account__r
                    WHERE (RecordTypeId =: clubRecordType.Id
                    AND Subscripption_Type__c != :POTENTIAL_DEAL) OR RecordTypeId =: ptsRecordType.Id Order by RecordTypeId)
                FROM Account
                WHERE Id =: accountId]);
        }
        return JSON.serialize(new Account());
    }//method:remoting:query

    /**
    * @desc dml on account personal details
    * @method updatePersonalDetails
    * @param 
    * @return 
    */
    @RemoteAction
    global static Response updatePersonalDetails(String accountJSONStr,SecureAccount secureAccount) {
        Response result = new Response();
        try{
            Account accountToUpdate = (Account)JSON.deserialize(accountJSONStr,Account.Class);
            update accountToUpdate;
            result.status = STATUS_OK;
            result.description = DESC_OK;
            return result;
        }catch(Exception e){
            result.status = STATUS_ERROR;
            result.description = DESC_ERROR;
            result.resultData = e.getMessage();
            result.stackTrace = e.getStackTraceString();
            return result;
        }
    }//method:remoting:dml  

    /**
    * @desc create cruise (account and employee application state)
    * @method saveCruiseEvent
    * @param cruiseJSONStr (String)
    * @return Response
    */
    @RemoteAction
    global static Response saveCruiseEvent(String cruiseJSONStr){
        Response result = new Response();
        try{
            Cruise__c cruiseItem = (Cruise__c)JSON.deserialize(cruiseJSONStr,Cruise__c.Class);
            // FIX-2018-07-19 - making sure there is a record type.
            if (String.isBlank(cruiseItem.RecordTypeId)) cruiseItem.RecordTypeId = '0120Y00000073Ap';
            //validate cruise
            if(cruiseItem.End_Date__c <= cruiseItem.Start_Date__c || 
                (SeatimeAuthenticationService.isGuestUser() && cruiseItem.Start_Date__c < DateTime.now())){
                result.status = STATUS_ERROR_NEGATIVE;
                result.description = Label.Negative_Error_Message;
                return result;
            }
            Integer startMinutes = cruiseItem.Start_Date__c.minute();
            Integer endMinutes = cruiseItem.End_Date__c.minute();
            if(Math.mod(startMinutes, 30) != 0){
                result.status = STATUS_ERROR_ROUND; 
                result.description = Label.Round_Error_Message;
                return result;
            }if(Math.mod(endMinutes, 30) != 0){
                //round end time to the closest 30 minuts round time.
                cruiseItem.End_Date__c = cruiseItem.End_Date__c.addMinutes(30 - Math.mod(endMinutes, 30));
            }
            //handle cruise
            handleCruiseItem(cruiseItem);
            //upsert cruise 
            upsert cruiseItem;
            result.status = STATUS_OK;
            result.description = DESC_OK;
            return result;
        }catch(Exception e){
            result.status = STATUS_ERROR;
            result.description = e.getMessage();//DESC_ERROR;
            result.resultData = e.getMessage();
            result.stackTrace = e.getStackTraceString();
            return result;
            throw e;
        }
    }//method:remoting:dml

    /**
    * @method handleCruiseItem
    * @desc handle account transaction and support employee or account state
    * @param cruiseItem (Cruise__c)
    * @return void
    */
    private static void handleCruiseItem(Cruise__c cruiseItem){
        //handle account transactions
        SchedulerService service = new SchedulerService();
        Id accountId = cruiseItem.AccountName__c;
        Id boatId = cruiseItem.Boat__c;

        Map<Id,Boats__c> accountBoats = getAccountBoats(accountId);
        Transaction__c transactionItem;
        String recordTypeName = getRecordTypeName(cruiseItem.RecordTypeId);
        if(recordTypeName == 'Club'){
            List <Transaction__c> pointsTrans = [select Id, Date_of_Transaction__c, Name, Type__c, Account_Name__c from Transaction__c where Account_Name__c =: accountId and RecordType.Name='נקודות' Order by Date_of_Transaction__c DESC limit 1];
            if(pointsTrans.size()>0){
                transactionItem = pointsTrans[0];
            }
            else{
                Map<Id,Transaction__c> idBoatTranObjMap = service.getAccTransaction(
                    accountId, 
                    accountBoats
                );

                //get transanction item
                transactionItem = idBoatTranObjMap != null && !idBoatTranObjMap.isEmpty() ? idBoatTranObjMap.get(boatId) : null;

                //open new transanction
                if(transactionItem == null || String.isBlank(transactionItem.Id) || Test.isRunningTest()){
                    Boats__c accountBoat = accountBoats != null && !accountBoats.isEmpty() ? accountBoats.get(boatId) : null;
                    String accountBoatType = accountBoat != null ? accountBoat.Type__c : '';
                    transactionItem = service.createTransaction(accountBoatType,accountId);
                }
            }  
        }else{ //SEAT-39
            List<Transaction__c> transactionList = new List<Transaction__c>();
            transactionList.addAll([SELECT Id,
                                          Name,
                                          Subscripption_Type__c
                                    FROM Transaction__c 
                                    WHERE Subscripption_Type__c =: NO_DEAL_TYPE]);
            transactionItem = !transactionList.isEmpty() ? transactionList[0] : null; 
        }
        //hook transanction
        cruiseItem.Transaction__c = transactionItem != null ? transactionItem.Id : null;
        //handle account state cruise status
        if(SeatimeAuthenticationService.isGuestUser()){
            cruiseItem.Status__c = 'Awaiting for Approval';
        }
    }//method:util


    /**
    * @desc org record types map
    * @method getCruiseRecordTypeMap
    * @return Map<Id,RecordType> 
    */
    private static Map<Id,RecordType> getCruiseRecordTypeMap(){
        return new Map<Id,RecordType> (
                [SELECT Id,
                        toLabel(Name),
                        DeveloperName,
                        SObjectType,
                        IsActive
                 FROM RecordType
                 WHERE IsActive = true
                 AND SObjectType = 'Cruise__c']);
    }//method:query 
    
    /**
     *  SEAT-39 Add RecorType Logic On Admin Side
     *  author Hadar Berman
     *
     *  @method getRecordTypeName
     *  @param  {Id} recordTypeId
     *  @return {String} recType.DeveloperName
     */
    private static String getRecordTypeName(Id recordTypeId){
        Map<Id,RecordType> cruiseRecordTypeMap = getCruiseRecordTypeMap();
        RecordType currentCruiseRecordType = cruiseRecordTypeMap.get(recordTypeId);
        return currentCruiseRecordType != null ? currentCruiseRecordType.DeveloperName : null;
    }//method:query 


    /**
    * @class Response
    */  
    global class Response {
        global String status {get;set;}
        global String description {get;set;}
        global String resultData {get;set;}
        global String stackTrace {get;set;}
    }//class:inner

    /**
    * @class SecureAccount
    */  
    global class SecureAccount {
        String securityToken {get;private set;}
        Account tokenizedAccount {get;private set;}

        global SecureAccount (String securityToken, Account tokenizedAccount){
            this.securityToken = securityToken;
            this.tokenizedAccount = tokenizedAccount;
        }
    }//class:inner    

    /**
    * @class translator
    */
    global class Translator {
        private Map<String,Map<String,String>> translationsMap {get;private set;}

        global Translator(){
            this.translationsMap = new Map<String,Map<String,String>>();
        }

        /**
        * @method addDictrionary
        * @requiers SchemaUtilityService
        * @param {String} fieldDictionaryName , {String} sobjectApiName , {String} fieldName
        */
        global void addDictrionary(String fieldDictionaryName,String sobjectApiName, String fieldName){
            this.translationsMap.put(
                fieldDictionaryName,
                SchemaUtilityService.getFieldLabelMap(sobjectApiName,fieldName)
            );
        }
    }//class:inner    

    global class DebugException extends Exception{}

} //class:controller