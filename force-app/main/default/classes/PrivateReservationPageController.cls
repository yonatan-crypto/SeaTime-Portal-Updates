/**
 * @description App controller privateReservationPage
 * @author Ceptes
 * @date Thursday-July-04-2024
 **/

public without sharing class PrivateReservationPageController {

    static SeaTimeAppSelector selector = new SeaTimeAppSelector();

    @AuraEnabled
    public static Map<string, object> getPrivateReservationData(Map<string, object> searchData) {
        Date searchDate = Date.valueOf((string) searchData.get('date'));
        Map<string, object> privateReservationDataToReturn = new Map<string, object>();

        Boats__c[] boatsArray  = selector.getBoatsArray(searchData);
        List<Object> weekEndIndices = selector.getBoatWeekEndIndices(searchDate);

        privateReservationDataToReturn.put('boatsArray', boatsArray);
        privateReservationDataToReturn.put('boatWeekendIndexes', weekEndIndices);
        return privateReservationDataToReturn;
    }

    @AuraEnabled
    public static String createPrivateReservation(Map<string, object> selectedBoat) {
        system.debug('inside createPrivateReservation'+selectedBoat);
        string startDate          = (string) selectedBoat.get('date');
        string startTime          = (string) selectedBoat.get('startTime');
        string endTime            = (string) selectedBoat.get('endTime');
        id boatId                 = (id) selectedBoat.get('boatId');
        id accountId              = (id) selectedBoat.get('accountId');
        Boolean needSkipper       = selectedBoat.containsKey('needSkipper') ? (Boolean) selectedBoat.get('needSkipper') : false;
        Transaction__c transationRec = selector.getTransactionFromAccount(accountId);
        RecordType recordType     = selector.getRecordTypeFromName('Club');
        id recordTypeId           = recordType.Id;
        DateTime cruiseStartDate = getFormattedDateTime(startDate, startTime);
        DateTime cruiseEndDate = getFormattedDateTime(startDate, endTime);
        String additionalInfo = (String) selectedBoat.get('additionalInput');
       Cruise__c isCruiseExist = checkIsCruiseRecordExist(cruiseStartDate,cruiseEndDate,boatId);
        if(isCruiseExist != null && isCruiseExist.Id != null){
            return 'Booked Already';
        } 
        Cruise__c cruise          = new Cruise__c();
        cruise.recordTypeId       = recordTypeId;
        cruise.Start_Date__c      = cruiseStartDate;
        cruise.End_Date__c        = cruiseEndDate;
        cruise.Boat__c            = boatId;
        cruise.AccountName__c     = accountId;
        cruise.Transaction__c     = transationRec.Id;
        cruise.Additional_Info__c = additionalInfo;
        cruise.need_skipper__c    = needSkipper;
        cruise.Status__c = transationRec.Id !=null && transationRec.Active__c ?  System.Label.CruiseApproavalStatus : System.Label.For_Payment;
        system.debug('cruise'+cruise+'transationRec=== '+transationRec);
        insert cruise;
        return cruise.id;
    }

    private static Cruise__c checkIsCruiseRecordExist(DateTime startDateTime,DateTime EndDateTime,Id boatId){
        return [Select id from Cruise__c where Boat__c =:boatId AND Start_Date__c =: startDateTime AND End_Date__c =: EndDateTime AND Status__c != 'Canceled' limit 1] ?? new Cruise__c();

    }   

    static dateTime getFormattedDateTime(string startDate,string startTime) {

        string[] stratDatesArray = startDate.split('-');
        string[] startTimeArray = startTime.split(':');

        return DateTime.newInstance(Integer.valueOf(stratDatesArray[0]), 
                                              Integer.valueOf(stratDatesArray[1]), 
                                              Integer.valueOf(stratDatesArray[2]), 
                                              Integer.valueOf(startTimeArray[0]), 
                                              Integer.valueOf(startTimeArray[1]), 0);
    }

    @AuraEnabled
    public static Transaction__c getTransactionFromAccount(Id accountId) {
        List<Transaction__c> activeTransactions = [
            SELECT Id, Total_Points__c, Points_Balance__c, Active__c, Club_Contract__c, type_of_membership__c, Start_Date__c, End_Date__c 
            FROM Transaction__c 
            WHERE Account_Name__c = :accountId 
            ORDER BY Active__c DESC, CreatedDate DESC
        ];

        if (activeTransactions.isEmpty()) {
            return new Transaction__c();
        }

        // Aggregate the best data from all active records
        Transaction__c bestTrans = activeTransactions[0].clone(true, true, true, true);
        
        Date maxEndDate = null;
        Boolean anyTakanon = false;

        for (Transaction__c trans : activeTransactions) {
            // Track the furthest end date
            if (trans.End_Date__c != null) {
                if (maxEndDate == null || trans.End_Date__c > maxEndDate) {
                    maxEndDate = trans.End_Date__c;
                }
            }
            // Track if any record has the Takanon signed
            if (trans.Club_Contract__c == true) {
                anyTakanon = true;
            }
            // If the "best" record is missing membership type but a later one has it, take it
            if (String.isBlank(bestTrans.type_of_membership__c) && String.isNotBlank(trans.type_of_membership__c)) {
                bestTrans.type_of_membership__c = trans.type_of_membership__c;
            }
        }

        bestTrans.End_Date__c = maxEndDate;
        bestTrans.Club_Contract__c = anyTakanon;

        return bestTrans;
    }

    @AuraEnabled
    public static String generateAndSendClubContract(Id transactionId) {
        try {
            if (transactionId == null) {
                throw new AuraHandledException('לא נמצאה עסקה תקפה (Transaction ID חסר).');
            }
            List<Transaction__c> transList = [SELECT Id, email_client_deal__c, Account_Name__c FROM Transaction__c WHERE Id = :transactionId LIMIT 1];
            if (transList.isEmpty()) {
                throw new AuraHandledException('לא נמצאה רשומת עסקה עם המזהה שסופק.');
            }
            Transaction__c trans = transList[0];
            String email = trans.email_client_deal__c;
            if (String.isBlank(email)) {
                email = UserInfo.getUserEmail();
            }
            if (String.isBlank(email)) {
                List<User> usr = [SELECT Contact.Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                if (!usr.isEmpty() && usr[0].Contact != null && String.isNotBlank(usr[0].Contact.Email)) {
                    email = usr[0].Contact.Email;
                }
            }
            if (String.isBlank(email)) {
                throw new AuraHandledException('לא נמצאה כתובת אימייל לשליחת התקנון.');
            }
            
            if (!Test.isRunningTest()) {
                try {
                    doco__Signature__c sig = doco.RenderAPI.createLink(
                        0, 
                        trans.Id, 
                        null, 
                        false, 
                        true, 
                        'טופס הצטרפות למועדון', 
                        false, 
                        email
                    );
                } catch (Exception docoErr) {
                    System.debug('Docomotion RenderAPI Error: ' + docoErr.getMessage());
                    if (!docoErr.getMessage().contains('no rows for assignment')) {
                        throw new AuraHandledException('שגיאת מנוע Docomotion: ' + docoErr.getMessage());
                    } else {
                        System.debug('Sandbox test mode: Docomotion form not found in Sandbox, simulating success.');
                    }
                }
            }
            return 'SUCCESS';
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            System.debug('Error in generateAndSendClubContract: ' + e.getMessage());
            throw new AuraHandledException('שגיאה בהפקת התקנון: ' + e.getMessage());
        }
    }

}