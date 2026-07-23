/**
 * @description Selector class for Sea time app
 * @author Ceptes
 * @date Saturday-June-29-2024
 **/  

public without sharing class SeaTimeAppSelector {
    
    // updated part for login to strong password.
    public Account[] isValidAccountCredentials(String userName) {
        return [
        SELECT Id,
               Phone,
               Login_Attempt__c,
               Student7Meter__c,
               StudentMeshit30__c,
               Is_Strong_Password__c,
               Strong_Password__c
        FROM Account
        WHERE Email__c = :userName
    ];
    }

    public Account getAccountFromId(Id accountId) {
        if (accountId == null) {
            return null;
        }

        List<Account> accList = [
            SELECT Id, Login_Attempt__c, Code__c,
                   Student7Meter__c, StudentMeshit30__c 
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        return accList.isEmpty() ? null : accList[0];
    }


    public Cruise__c[] getRecentCruiseRecords(Id accountId) {
        return [SELECT id, Boat__r.Name, Start_Time__c, Start_Date__c, End_Date__c, saildate__c, cruise_time_formula__c,
                RecordType.Name, Duration_HHMM__c, Boat__r.Type__c, 
                Status__c, RemaingSeatsInBoat__c, Additional_Info__c, Skipper__r.Name,
                Course_Type__c, IsPrivateCourse__c, AccountName__c, type_of_enriching__c,
                (SELECT id, Account_Co__c FROM Co_Cruise_Sailres__r where Account_Co__c =:accountId )
                FROM Cruise__c WHERE Start_Date__c >=: System.now() ORDER BY Start_Date__c];
    }

    public Cruise__c getCruiseRecord(id cruiseId) {
        return [SELECT id, RemaingSeatsInBoat__c FROM Cruise__c WHERE id=: cruiseId LIMIT 1 FOR UPDATE];
    }

    public PriceListLine__c[] getPriceListLinesFromBoatIds(String boatIdsArray) { 
        List<PriceListLine__c> finalPriceListLineList = new List<PriceListLine__c>();
        Date minDate;
        Date maxDate;
        Map<String, List<Object>> cruiseMap  = new Map<String, List<Object>>();
        Map<String, PriceListLine__c> priceListLineData = new Map<String, PriceListLine__c>();
        List<Object> clubCruisesArray = (List<Object>)JSON.deserializeUntyped(boatIdsArray);
        for(Object cruiseObject: clubCruisesArray) {
            Map<String, Object> cruiseData = (Map<String, Object>)cruiseObject;
            Date cruiseStartDate = Date.valueOf((String)cruiseData.get('startDate'));
            Time cruiseStartTime = ((DateTime)JSON.deserialize('"' + (String)cruiseData.get('startDate') + '"', DateTime.class)).time() ;
            if(minDate == NULL && maxDate == NULL){
                minDate = maxDate = cruiseStartDate;
            }
            if(cruiseStartDate < minDate) { minDate = cruiseStartDate; }
            if(cruiseStartDate > maxDate) { maxDate = cruiseStartDate; }
            String cruiseRecordTypeName = (String)cruiseData.get('recordTypeName');
            String cruiseBoatId = (String)cruiseData.get('boatId');
            String cruiseId = (String)cruiseData.get('id');
            if(!cruiseMap.containsKey(cruiseRecordTypeName)){
                cruiseMap.put(cruiseRecordTypeName, new List<Object>{cruiseObject});
            }
            else{
                cruiseMap.get(cruiseRecordTypeName).add(cruiseObject); 
            }
            if(cruiseRecordTypeName == 'Course'){
                PriceListLine__c coursePriceListLine= new PriceListLine__c(Price__c=0,Boat__c =cruiseBoatId,
                                                           Start__c=cruiseStartTime,Type__c=cruiseRecordTypeName);
                priceListLineData.put(cruiseRecordTypeName+cruiseStartDate+cruiseBoatId+cruiseId,coursePriceListLine); 
            }
        }
        for(PriceListLine__c priceListLine: [SELECT id, Price__c, Start__c,Type__c, Boat__c,
                                             PriceList__r.Start_Date__c,PriceList__r.End_Date__c FROM 
                                             PriceListLine__c WHERE Type__c != 'Club' AND PriceList__r.Start_Date__c<= :minDate AND
                                             (PriceList__r.End_Date__c >= :maxDate OR PriceList__r.End_Date__c = null) ORDER BY PriceList__r.CreatedDate]){
                   if(cruiseMap.containsKey(priceListLine.Type__c)){
                    for(Object cruiseObject: cruiseMap.get(priceListLine.Type__c)){
                        Map<String, Object> cruiseData = (Map<String, Object>)cruiseObject;
                        Date cruiseStartDate = Date.valueOf((String)cruiseData.get('startDate'));
                        String cruiseRecordTypeName = (String)cruiseData.get('recordTypeName');
                        String cruiseBoatId = (String)cruiseData.get('boatId');
                        String cruiseId = (String)cruiseData.get('id');
                        Time cruiseStartTime = ((DateTime)JSON.deserialize('"' + (String)cruiseData.get('startDate') + '"', DateTime.class)).time() ;
                        
                        Boolean isDateInRange = cruiseStartDate >= priceListLine.PriceList__r.Start_Date__c && 
                                                (priceListLine.PriceList__r.End_Date__c == null || cruiseStartDate <= priceListLine.PriceList__r.End_Date__c);

                        if(isDateInRange && cruiseBoatId == priceListLine.Boat__c && cruiseRecordTypeName == priceListLine.Type__c){
                               if(!priceListLineData.containsKey(priceListLine.Type__c+cruiseStartDate+cruiseBoatId)){
                                   priceListLineData.put(priceListLine.Type__c+cruiseStartDate+cruiseBoatId+cruiseId, priceListLine);
                               }
                           }
                           else if(isDateInRange && (cruiseRecordTypeName == 'Friends' || cruiseRecordTypeName == 'Enriching')){
                                  if(!priceListLineData.containsKey(priceListLine.Type__c+cruiseStartDate+cruiseBoatId)){
                                      PriceListLine__c tempPriceListLine= new PriceListLine__c(Price__c=priceListLine.Price__c,Boat__c =cruiseBoatId,
                                                           Start__c=cruiseStartTime,Type__c=cruiseRecordTypeName);
                                      priceListLineData.put(priceListLine.Type__c+cruiseStartDate+cruiseBoatId+cruiseId, tempPriceListLine); 
                               }
                         }
                    }
                                             }
        }
        for (String key : priceListLineData.keySet()) {
            finalPriceListLineList.add(priceListLineData.get(key));
		}
        
        return finalPriceListLineList;
    }

    public Boats__c[] getBoatsArray(Map<string, Object> searchData) {
        Object[] boatTypesArrayObject = (Object[]) searchData.get('boatTypes');
        String[] boatTypesArray = String.join(boatTypesArrayObject, ';').split(';');
        Date searchDate = Date.valueOf((string) searchData.get('date'));
        String accountIdStr = (String) searchData.get('accountId');
        Id accountId = String.isNotBlank(accountIdStr) ? (Id)accountIdStr : null;
        Date nextDate = searchDate.addDays(1);
        return [SELECT id, Name, Type__c,
                (SELECT id, Start_Time__c, End_Time__c, Duration__c 
                FROM Boat_Availability__r 
                WHERE Start_Date__c <=: searchDate
                AND End_Date__c >=: searchDate AND Active__c = true),
                (SELECT id,HPrice__c,Price__c, Start__c,Type__c 
                FROM PriceListLines__r where PriceList__r.Start_Date__c <=:searchDate  AND PriceList__r.End_Date__c>=:searchDate AND Type__c = 'Club' ORDER BY LastModifiedDate desc),
                (SELECT id, Boat__c, Account_Name__c, Expiration_Date__c 
                FROM Certified_boat__r
                WHERE Account_Name__c = :accountId),
                (select id,name,status__c, Start_Date__c, End_Date__c from Boat__r  WHERE Start_Date__c < :nextDate
                AND End_Date__c > :searchDate AND Status__c Not IN ('Canceled')  order by Start_Date__c)
                FROM Boats__c WHERE Type__c IN:boatTypesArray
                AND Active__c = true LIMIT 10000];
    }

    public List<Object> getBoatWeekEndIndices(Date searchDate) {
        List<Object> weekEndIndices = new List<Object>();
      // Map of boolean field to corresponding day index
      Map<String, Integer> dayMap = new Map<String, Integer>{
        'Is_Sunday__c' => 0,'Is_Monday__c' => 1, 'Is_Tuesday__c' => 2, 'Is_Wednesday__c' => 3,
        'Is_Thursday__c' => 4, 'Is_Friday__c' => 5, 'Is_Saturday__c' => 6        
        };

        // Query the Boat_Weekends__c record
        Boat_Weekends__c bwRecord = [SELECT Id, Is_Monday__c, Is_Tuesday__c, Is_Wednesday__c, 
                                    Is_Thursday__c, Is_Friday__c, Is_Saturday__c, Is_Sunday__c 
                                    FROM Boat_Weekends__c 
                                    WHERE Is_Active__c = true 
                                    AND Start_Date__c <= :searchDate 
                                    AND End_Date__c >= :searchDate 
                                    LIMIT 1] ?? new Boat_Weekends__c();

    // If no record is found, return an empty list
    if (bwRecord.Id == null) {
        return new List<Object>();
    }
    
    // Loop through the map and add the index if the corresponding field is true
    for (String field : dayMap.keySet()) {
        if ((Boolean) bwRecord.get(field)) {
            weekEndIndices.add(dayMap.get(field));
        }
    }

    return weekEndIndices;
    }
    public RecordType getRecordTypeFromName(string recordTypeName) {
        return [SELECT id FROM RecordType WHERE name =: recordTypeName];
    }

    public Transaction__c getTransactionFromAccount(Id accountId) {
        List<Transaction__c> transList = [SELECT id, Total_Points__c,Points_Balance__c,Active__c,Club_Contract__c, type_of_membership__c, Start_Date__c, End_Date__c 
                                          FROM Transaction__c 
                                          WHERE Account_Name__c =: accountId 
                                          AND type_of_membership__c != null 
                                          ORDER BY Active__c DESC, CreatedDate DESC 
                                          LIMIT 1];
        if (!transList.isEmpty()) {
            return transList[0];
        }
        return new Transaction__c();
    }

    public List<Co_Cruise_Members__c> getPastClubCruises(Id accountId) {
        return [SELECT Id, Name, Date__c, Cruise__r.Name, Cruise__r.Boat__r.Name, 
                       Cruise__r.Additional_Info__c, Status__c, SailType__c,
                       Cruise_Points__c, Cruise__r.Start_Date__c, Cruise__r.End_Date__c
                FROM Co_Cruise_Members__c 
                WHERE Account_Co__c = :accountId 
                AND Cruise__r.Start_Date__c < TODAY
                AND Status__c != 'Canceled'
                ORDER BY Cruise__r.Start_Date__c DESC];
    }
}