public without sharing class SchedulerService {

    private static final String LABEL_DELIMITER = ':';
    private static final String SLOT_DELIMITER = '-';
    private static final String SUBSCRIPTION_RECORD_TYPE_DEV_NAME = 'Subscription';
    private static final String CLUB_RECORD_TYPE_DEV_NAME = 'Club';

    private Id accountId;
    private Integer numOfDays;
    private Map<String, Set<Slot>> settingsMap = new Map<String, Set<Slot>>();
    private Map<Boats__c, List<Cruise__c>> existCruiseMap = new Map<Boats__c, List<Cruise__c>>();
    private Map<Datetime, List<Cruise__c>> cruiseByDayMap = new Map<Datetime, List<Cruise__c>>();
    private Map<Id,Boats__c> idBoatsObjMap = new Map<Id,Boats__c>();
    private Map<Id,Transaction__c> boatIdTranObjMap = new Map<Id,Transaction__c>();
    private List<Datetime> daysList = new List<Datetime>();
    private List<Transaction__c> tranList = new List<Transaction__c>();
    private Set<String> boatNameSet = new Set<String>();
    private static RecordType subscriptionRecordType = [SELECT Id,Name,DeveloperName 
                                                        FROM RecordType 
                                                        WHERE DeveloperName =: SUBSCRIPTION_RECORD_TYPE_DEV_NAME 
                                                        AND SObjectType = 'Transaction__c' LIMIT 1];

    private static RecordType clubRecordType = [SELECT Id,Name,DeveloperName 
                                                 FROM RecordType 
                                                 WHERE DeveloperName =: CLUB_RECORD_TYPE_DEV_NAME 
                                                 AND SObjectType = 'Cruise__c' LIMIT 1];

    private Date currentSchedulerDateValue; //= System.today();

    public SchedulerService(){}

    public SchedulerService(Id accountId, Integer numOfDays, Map<Id,Boats__c> idBoatsObjMap, Date selectedDate){
        this.currentSchedulerDateValue = selectedDate != null ? selectedDate : System.today(); 
        this.accountId = accountId;
        this.numOfDays = numOfDays;
        this.idBoatsObjMap = idBoatsObjMap;
        getSettings();
        getExistingCruise(); 
    }

    private void getSettings(){
        List<Customer_Setting__mdt> settingsList = [SELECT Id, 
                                                           Label, 
                                                           Start_time__c, 
                                                           End_time__c
                                                    FROM Customer_Setting__mdt];
        Set<String> typesNames = new Set<String>();
        for(Customer_Setting__mdt settingItem : settingsList){
            typesNames.add(getBoatType(settingItem.Label));
        }
        for(String typeItem : typesNames){
            Set<Slot> dailySlotsSet = new Set<Slot>();
            for(Customer_Setting__mdt settingItem : settingsList){
                if(typeItem.equals(getBoatType(settingItem.Label))){
                    Slot sl = stringToSlot(settingItem);
                    dailySlotsSet.add(sl);
                }
            }
            settingsMap.put(typeItem, dailySlotsSet);
        }
    }

    private void getExistingCruise(){
        Set<String> accountCruiseStatusSet = new Set<String>{
            'Guide Matching',
            'For Payment',
            'Awaiting for Approval',
            'Ready',
            'No Qualification',
            'Approved',
            'Canceled'
        };
        Date rangeBoundryDate = this.currentSchedulerDateValue + this.numOfDays;
        List<Cruise__c> cruiseList = [SELECT Id, Name, Start_Date__c,RecordTypeId,RecordType.DeveloperName,
                                             End_Date__c, AccountName__c, AccountName__r.Name,
                                             Transaction__c, Guide__c, Boat__c, Type__c, Type2__c,
                                             Status__c, Subject__c, Boat_Name__c,
                                             Co_Cruise__c,Additional_Info__c
                                      FROM Cruise__c
                                      WHERE Boat__c IN : idBoatsObjMap.keySet() AND Start_Date__c < :rangeBoundryDate 
                                      AND ((AccountName__c =: this.accountId AND Status__c IN :accountCruiseStatusSet)
                                      OR (AccountName__c !=: this.accountId AND Status__c != 'Canceled'))
                                      ORDER BY Start_Date__c ASC];

        this.existCruiseMap = listToMap(cruiseList);
        this.cruiseByDayMap = listToDateMap(cruiseList);
    }

    public List<Cruise__c> prepareScheduler(){
        List<Cruise__c> boatCruiseList = new List<Cruise__c>();
        for(Boats__c boatItem : this.existCruiseMap.keySet()) {
            system.debug('Name: ' + boatItem.Name);
            for(Datetime day : daysList) {
                if(this.settingsMap.get(boatItem.Type__c) != null) {
                    boatCruiseList.addAll(
                        setTimeSlots(
                            this.settingsMap.get(boatItem.Type__c),
                            getcruisByDate(day,boatItem.Id),
                            boatItem.Id,
                            day)
                        );
                }
            }
        }
        return boatCruiseList;
    }

    public Map<Id,Transaction__c> getAccTransaction(Id accountId, Map<Id,Boats__c> idBoatsObjMap) {
        //Id subscriptionRecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Subscription').getRecordTypeId(); //schema returns hebrew keys
        system.debug('subscriptionRecordType: '+subscriptionRecordType);
        tranList = [SELECT Id, Name, Type__c, Account_Name__c
                    FROM  Transaction__c
                    WHERE Account_Name__c =: accountId 
                    AND RecordTypeId =: subscriptionRecordType.Id];


        for(Boats__c boatItem : idBoatsObjMap.values()) {
            for(Transaction__c tranItem : tranList) {
                if(boatItem.Type__c == tranItem.Type__c) {
                    this.boatIdTranObjMap.put(boatItem.Id, tranItem);
                }
            }
        }
        return boatIdTranObjMap;
    }

    public List<Cruise__c> setTimeSlots(Set<Slot> timeSlots,List<Cruise__c> existingCruiseList, Id boatId, DateTime day){
        Map<String,Cruise__c> dateTimeCruiseMap = new Map<String,Cruise__c>();
        Set<Slot> timeSetOccupid = new Set<Slot>();
        Set<Slot> timeSetPartial = new Set<Slot>();
        Set<Slot> timeSetNew = new Set<Slot>();

        timeSetNew.addAll(timeSlots);

        Integer index = 0;
        for(Cruise__c cr : existingCruiseList){
            if(cr.AccountName__c != this.accountId){
                cr.AccountName__c = '000000000000000000';
                cr.Status__c = 'Occupied';
                //cr.Name = ''; : nullify in client only (read-only)
            }
            Time startTime = cr.Start_Date__c.time();
            Time endTime = cr.End_Date__c.time();
            String key = String.valueOf(cr.Start_Date__c.format('HH:mm') + '-' + cr.End_Date__c.format('HH:mm'));
            dateTimeCruiseMap.put(key,cr);
            for(Slot tm : timeSlots){
                Time startSlot = tm.startTime;
                Time endSlot = tm.endTime;
                if(startTime < startSlot && endTime > endSlot){
                    system.debug('do nothing');
                    timeSetOccupid.add(tm);
                    timeSetNew.remove(tm);
                }
                if(startTime >= startSlot && startTime <= endSlot){
                    if(startTime == startSlot && endTime >= endSlot){
                        system.debug('do nothing');
                        timeSetOccupid.add(tm);
                        timeSetNew.remove(tm);
                    }
                    if(startTime > startSlot && endTime >= endSlot){
                        system.debug('partial before : ' + tm);
                        if(index > 0 && existingCruiseList[index-1] != null && existingCruiseList[index-1].End_Date__c.time() > startSlot){
                            system.debug('create : ' + existingCruiseList[index-1].End_Date__c.time() + '-' + startTime);
                            if(existingCruiseList[index-1].End_Date__c.time() < startTime) {
                                dateTimeCruiseMap.put(timeToString(existingCruiseList[index-1].End_Date__c.time()) + '-' + timeToString(startTime),
                                    createCruiseItem(day,existingCruiseList[index-1].End_Date__c.time(),startTime, boatId));
                            }
                        } else {
                            system.debug('create : ' + startSlot + '-' + startTime);
                            dateTimeCruiseMap.put(timeToString(startSlot) + '-' + timeToString(startTime),createCruiseItem(day,startSlot,startTime, boatId));
                        }
                        timeSetPartial.add(tm);
                    }

                }
                if(endTime > startSlot && endTime <= endSlot){
                    if(startTime <= startSlot && endTime < endSlot){
                        system.debug('partial after : ' + tm);
                        if(index < existingCruiseList.size()-1 && existingCruiseList[index+1] != null && existingCruiseList[index+1].Start_Date__c.time() < endSlot){
                            system.debug('create : ' + endTime + existingCruiseList[index+1].Start_Date__c.time());
                            if(endTime < existingCruiseList[index+1].Start_Date__c.time()) {
                                dateTimeCruiseMap.put(timeToString(endTime) + SLOT_DELIMITER + timeToString(existingCruiseList[index+1].Start_Date__c.time()),
                                    createCruiseItem(day,endTime,existingCruiseList[index+1].Start_Date__c.time(), boatId));
                            }
                        } else {
                            system.debug('create : ' + endTime + '-' + endSlot);
                            dateTimeCruiseMap.put(timeToString(endTime) + SLOT_DELIMITER + timeToString(endSlot),createCruiseItem(day,endTime,endSlot, boatId));
                        }
                        timeSetPartial.add(tm);
                    }
                }
                timeSetNew.removeAll(timeSetPartial);
            }
            index++;
        }

        for(Slot ncr : timeSetNew){
            Time startSlot = ncr.startTime;                                                    
            Time endSlot = ncr.endTime;                                                        
            String key = timeToString(startSlot) + SLOT_DELIMITER + timeToString(endSlot);
            dateTimeCruiseMap.put(key,createCruiseItem(day,startSlot,endSlot, boatId));
        }
        system.debug('created : ' + dateTimeCruiseMap.keySet());
        return dateTimeCruiseMap.values();
    }

    public Cruise__c createCruiseItem(DateTime day,Time startTime,Time endTime,Id boatId) {
        Date curDate = date.newinstance(day.year(), day.month(), day.day());
        Cruise__c cruiseItem = new Cruise__c();
        cruiseItem.Boat__c = boatId;
        cruiseItem.Status__c = 'Ready';
        cruiseItem.AccountName__c = this.accountId;
        Datetime startDatetime = Datetime.newInstance(curDate,startTime);
        Datetime endDatetime = Datetime.newInstance(curDate,endTime);

        cruiseItem.Start_Date__c = startDatetime;
        cruiseItem.End_Date__c = endDatetime;
        cruiseItem.RecordTypeId = clubRecordType.Id;

        return cruiseItem;
    }

    public Transaction__c createTransaction(String boatType, Id accountId){
        if(Test.isRunningTest()){
            Transaction__c newTransaction = new Transaction__c();
            newTransaction.Name = 'Potential Deal';
            newTransaction.Account_Name__c = accountId;
            newTransaction.Date_of_Transaction__c = this.currentSchedulerDateValue;
            newTransaction.Start_Date__c = this.currentSchedulerDateValue;
            newTransaction.End_Date__c = this.currentSchedulerDateValue;
            newTransaction.Type__c = boatType;
            newTransaction.Total_Hours__c = 0;
            newTransaction.weekday__c = 0;
            newTransaction.weekend__c = 0;
            //newTransaction.Subscripption_Type__c = 'Potential Deal';
            insert newTransaction;
            
            return newTransaction;
        }
        throw new QueryException(Label.No_Transaction_Found);
        return null;
    }
    
    /**
     *  SEAT-31 Classroom And Employee Event On Admin Calendar Side
     *  author Hadar Berman
     *
     *  @method   getEmployeeClassroomEvents
     *  @return   {Map<String, List<Event>>} eventMap
     */
    public Map<String, List<Event>> getEmployeeClassroomEvents(){
        List<Event> employeeEventList = new List<Event>();
        List<Event> classroomEventList = new List<Event>();
        Map<String, List<Event>> eventMap = new Map<String, List<Event>>();
        
        List<Event> eventList = [SELECT Id, What.Name, Subject, Account__c,Account__r.Name, Task_Number__c, Description__c, 
                                        StartDateTime, EndDateTime, Is_Locked__c, Origin__c 
                                 FROM Event
                                 WHERE Is_Locked__c = true
                                 AND Origin__c != null];
                                 
        if(!eventList.isEmpty()){
            for(Event eventItem : eventList){
                if(eventItem.Origin__c.contains('Employee')){
                    eventItem.Description__c = eventItem.What.Name+':'+eventItem.Subject;
                    employeeEventList.add(eventItem);
                }
                if(eventItem.Origin__c.contains('Classroom')){
                    eventItem.Description__c = eventItem.What.Name+':'+eventItem.Subject;
                    classroomEventList.add(eventItem);
                }
            }
            eventMap.put('Employee',employeeEventList);
            eventMap.put('Classroom',classroomEventList);
        }
        return eventMap;
    }

    private List<Cruise__c> getcruisByDate(Datetime reqDate, Id boatId){
        List<Cruise__c> crByDayList = new List<Cruise__c>();
        List<Cruise__c> newCruiseList = new List<Cruise__c>();
        crByDayList = cruiseByDayMap.get(reqDate);

        for(Cruise__c cruiseItem : crByDayList){
            if(cruiseItem.Boat__c == boatId){
                newCruiseList.add(cruiseItem);
            }
        }
        return newCruiseList;
    }

    private String getBoatType(String label){
        return label.substringBefore(LABEL_DELIMITER);
    }

    private Map<Boats__c, List<Cruise__c>> listToMap(List<Cruise__c> cruiseList){
        Map<Boats__c, List<Cruise__c>> cruiseMap = new Map<Boats__c, List<Cruise__c>>();
        for(Boats__c boatItem : this.idBoatsObjMap.values()){
            List<Cruise__c> cruisesOfBoatList = new List<Cruise__c>();
            for(Cruise__c cruiseItem : cruiseList){
                if(cruiseItem.Boat__c == boatItem.Id){
                    cruisesOfBoatList.add(cruiseItem);
                }
            }
            cruiseMap.put(boatItem, cruisesOfBoatList);
        }
        return cruiseMap;
    }

    private Map<Datetime, List<Cruise__c>> listToDateMap(List<Cruise__c> cruiseList){
        Map<Datetime, List<Cruise__c>> cruiseDateMap = new Map<Datetime, List<Cruise__c>>();
        for(Integer i = 0; i< this.numOfDays; i++){
            this.daysList.add(this.currentSchedulerDateValue + i);
        }

        for(Datetime day : this.daysList){
            List<Cruise__c> dailyCruiseList = new List<Cruise__c>();
            for(Cruise__c cruiseItem : cruiseList){
                if(cruiseItem.Start_Date__c.date() == day.date()){
                    dailyCruiseList.add(cruiseItem);
                }
            }
            cruiseDateMap.put(day, dailyCruiseList);
        }
        return cruiseDateMap;
    }
    @testVisible
    private Slot stringToSlot(Customer_Setting__mdt settingItem){
        Slot sl = new Slot();
        sl.startTime = Time.newInstance(Integer.valueOf(settingItem.Start_time__c.substring(0,2)), Integer.valueOf(settingItem.Start_time__c.substringAfter(LABEL_DELIMITER)),0,0);
        sl.endTime = Time.newInstance(Integer.valueOf(settingItem.End_time__c.substring(0,2)), Integer.valueOf(settingItem.End_time__c.substringAfter(LABEL_DELIMITER)),0,0);
        return sl;
    }

    private string timeToString(Time tm){
        return String.valueOf(tm).substring(0,5);
    }
    @testVisible
    private Class Slot {
        public Time startTime;
        public Time endTime;
    }

    public class DebugException extends Exception{}
}


//when system local is diffrent then the user local
//Datetime now = Datetime.now();
//Integer offset = UserInfo.getTimezone().getOffset(now);
//.addSeconds(offSet/1000);
//.addSeconds(offSet/1000);