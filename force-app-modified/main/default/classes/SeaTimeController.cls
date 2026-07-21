/**
 * @description App controller subscription page
 * @author Ceptes
 * @date Thursday-July-04-2024
 **/
public without sharing class SeaTimeController {
    
    @AuraEnabled(cacheable=true)
    public static String getSubscriptionDetails(String accId) {
        Map<String, Object> result = new Map<String, Object>();
        if(String.isBlank(accId)) return JSON.serialize(result);
        
        try {
            Id accountId = (Id)accId;
            
            List<Account> accounts = [SELECT Id, Name, StudentMeshit30__c FROM Account WHERE Id = :accountId LIMIT 1];
            if (accounts.isEmpty()) return JSON.serialize(result);
            Account acc = accounts[0];

            result.put('id', acc.Id);
            result.put('name', acc.Name);
            result.put('StudentMeshit30__c', acc.StudentMeshit30__c);
            
            // Direct query for transactions
            List<Transaction__c> transactions = [SELECT Id, Name, Extra_Subscription_Details__c, Active__c, Start_Date__c, End_Date__c, Total_Points__c, Used_Points__c, Points_Balance__c 
                                                FROM Transaction__c 
                                                WHERE Account_Name__c = :accountId 
                                                ORDER BY Active__c DESC, CreatedDate DESC];
            result.put('Account__r', transactions);
            
            // Cruises
            List<Cruise__c> cruises = [SELECT Id, Transaction__c, Start_Date__c, End_Date__c, Cruise_Points__c, Active_Total_Hours__c, Boat__r.Name, Status__c 
                                      FROM Cruise__c 
                                      WHERE AccountName__c = :accountId 
                                      ORDER BY Start_Date__c DESC];
            result.put('Cruises__r', cruises);
                                      
            // Guided Cruises
            List<Co_Cruise_Members__c> guidedCruises = [SELECT Id, Transaction__c, Cruise__c, Date__c, Cruise_Points__c, Extra_Information__c, Status__c, Name_of_Boat__c, SailType__c, Cruise__r.RecordType.Name, Cruise__r.Additional_Info__c 
                                                       FROM Co_Cruise_Members__c 
                                                       WHERE Account_Co__c = :accountId 
                                                       AND Cruise__c != null 
                                                       ORDER BY Cruise__r.Start_Date__c DESC];
            result.put('Co_Cruise_Sailres__r', guidedCruises);
            
            return JSON.serialize(result);
        } catch (Exception e) {
            result.put('error', e.getMessage());
            return JSON.serialize(result);
        }
    }

    @AuraEnabled 
    public static string updateCruiseStatus(String cruiseId){
        try {
            Cruise__c cruise = [SELECT Id, Status__c, Start_Date__c FROM Cruise__c WHERE Id = :cruiseId LIMIT 1];
            Set<String> fortyEightHourStatuses = new Set<String>{'Approved', 'For Payment', 'No Qualification'};
            if (fortyEightHourStatuses.contains(cruise.Status__c)) {
                Datetime fortyEightHoursFromNow = Datetime.now().addHours(48);
                if (cruise.Start_Date__c < fortyEightHoursFromNow) {
                    return 'Error: Cannot cancel within 48 hours of departure.';
                }
            }
            cruise.Status__c = 'Canceled';
            update cruise;
            return 'Success';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String cancelCoCruiseMember(String memberId) {
        try {
            Co_Cruise_Members__c member = [SELECT Id, Date__c FROM Co_Cruise_Members__c WHERE Id = :memberId LIMIT 1];
            Datetime twentyFourHoursFromNow = Datetime.now().addHours(24);
            if (member.Date__c < twentyFourHoursFromNow) {
                return 'Error: Cannot cancel within 24 hours of departure.';
            }
            delete member;
            return 'Success';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String cancelCoCruiseSailres(String sailresId) {
        return cancelCoCruiseMember(sailresId);
    }

    @AuraEnabled
    public static Decimal calculateCruisePrice(Object cruiseRec) {
        try {
            if (cruiseRec == null) return 0;

            String jsonStr = JSON.serialize(cruiseRec);
            Map<String, Object> cruiseMap = (Map<String, Object>)JSON.deserializeUntyped(jsonStr);
            
            Id boatId = (Id)cruiseMap.get('Boat__c');
            Object startObj = cruiseMap.get('Start_Date__c');
            Object endObj = cruiseMap.get('End_Date__c');
            Boolean isHoliday = (Boolean)cruiseMap.get('Holiday__c');
            Id transactionId = (Id)cruiseMap.get('Transaction__c');

            if (boatId == null || startObj == null || endObj == null) return 0;

            DateTime startTime;
            DateTime endTime;

            if (startObj instanceof String) {
                startTime = (DateTime)JSON.deserialize('"' + (String)startObj + '"', DateTime.class);
            } else {
                startTime = (DateTime)JSON.deserialize(JSON.serialize(startObj), DateTime.class);
            }

            if (endObj instanceof String) {
                endTime = (DateTime)JSON.deserialize('"' + (String)endObj + '"', DateTime.class);
            } else {
                endTime = (DateTime)JSON.deserialize(JSON.serialize(endObj), DateTime.class);
            }

            if (startTime == null || endTime == null) return 0;

            Date dt = startTime.date();
            
            // 1. Try Sale PriceLists
            List<PriceList__c> dispricelists = [SELECT Id, Price__c, Start_Date__c, End_Date__c, 
                                               (SELECT Id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c FROM PriceListLines__r ORDER BY Start__c) 
                                               FROM PriceList__c WHERE Type__c = 'מבצע' ORDER BY Start_Date__c DESC];
            
            for (PriceList__c pl : dispricelists) {
                if (pl.Start_Date__c <= dt && (pl.End_Date__c == null || pl.End_Date__c >= dt)) {
                    return TransactionPoints.getPTS('Club', boatId, isHoliday == true || isWeekend(dt), pl.PriceListLines__r, pl.Price__c, startTime, endTime);
                }
            }

            // 2. Try Regular PriceLists based on Transaction Date
            Date transDate = dt;
            if (transactionId != null) {
                List<Transaction__c> transList = [SELECT Date_of_Transaction__c FROM Transaction__c WHERE Id = :transactionId LIMIT 1];
                if (!transList.isEmpty() && transList[0].Date_of_Transaction__c != null) transDate = transList[0].Date_of_Transaction__c;
            }

            List<PriceList__c> regpricelists = [SELECT Id, Price__c, Start_Date__c, End_Date__c, 
                                               (SELECT Id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c FROM PriceListLines__r ORDER BY Start__c) 
                                               FROM PriceList__c WHERE Type__c = 'רגיל' ORDER BY Start_Date__c DESC];
            
            for (PriceList__c pl : regpricelists) {
                if (pl.Start_Date__c <= transDate && (pl.End_Date__c == null || pl.End_Date__c >= transDate)) {
                    return TransactionPoints.getPTS('Club', boatId, isHoliday == true || isWeekend(dt), pl.PriceListLines__r, pl.Price__c, startTime, endTime);
                }
            }

            return 0;
        } catch (Exception e) {
            return 0;
        }
    }

    private static Boolean isWeekend(Date dt) {
        Date startOfWeek = dt.toStartOfWeek();
        Integer dayDiff = startOfWeek.daysBetween(dt);
        return dayDiff == 5 || dayDiff == 6; // Friday or Saturday
    }
}