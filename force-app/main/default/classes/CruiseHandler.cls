/*
* @Author: ZedXagE 
* @Date: 2019-04-23 11:10:31 
* @Last Modified by: ZedXagE
* @Last Modified time: 2019-04-23 13:53:06
*/

public without sharing class CruiseHandler {
    public static Boolean firstRun = true;
    private hlp_triggerChanges isChangedHelper = new hlp_triggerChanges();
    private CruiseManager manager = new CruiseManager();
    private final String CLUB_RECORD_TYPE_DEV_NAME = 'Club';
    public void checkAccountHasCertificate(List < Cruise__c > newList) {
        Set < Id > AccIdSet = new Set < Id > ();
        List < Cruise__c > clubCruiseList = new List < Cruise__c > ();
        Map < Id, Account > cruiseToAccountMap = new Map < Id, Account > ();
        //Id subscriptionRecordTypeId = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Subscription').getRecordTypeId(); //schema returns hebrew keys
        RecordType clubRecordType = [SELECT Id, Name, DeveloperName
                                     FROM RecordType
                                     WHERE DeveloperName =: CLUB_RECORD_TYPE_DEV_NAME LIMIT 1
                                    ];
        for (Cruise__c crs: newList) {
            if (crs.RecordTypeId == clubRecordType.Id) {
                AccIdSet.add(crs.AccountName__c);
                clubCruiseList.add(crs);
            }
        }
        if (AccIdSet != null && !AccIdSet.isEmpty()) {
            Map < Id, Account > realatedAccountMap = new Map < Id, Account > (
                [Select Id, Name,
                 (Select Name, Boat__c From Account_Name__r)
                 From Account
                 WHERE Id in: AccIdSet
                ]);
            for (Cruise__c cruiseItem: clubCruiseList) {
                Account relatedAccount = realatedAccountMap.get(cruiseItem.AccountName__c);
                if (relatedAccount != null) {
                    cruiseToAccountMap.put(cruiseItem.Id, relatedAccount);
                }
            }
            manager.checkAccountHasCertificate(clubCruiseList, cruiseToAccountMap);
        }
    }
    public void CalculateExtraHours(List < Cruise__c > newList, Set <String> statchanged) {
        String clubrectype = [select id from RecordType where Name = 'Club'
                              and SobjectType = 'Cruise__c'
                             ].id;
        Set < String > transids = new Set < String > ();
        Set <String> transchanged = new Set <String>();
        for (Cruise__c crs: newList)
            if (crs.Transaction__c != null){
                if (crs.RecordTypeid == clubrectype) transids.add(crs.Transaction__c);
            }
        //query
        List < PriceList__c > dispricelists = [select id, Type__c, Start_Date__c, End_Date__c, Price__c, (select id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c from PriceListLines__r
                                                                                                          Order by Start__c) from PriceList__c Where Type__c = 'מבצע'
                                               Order by Start_Date__c DESC
                                              ];
        List < PriceList__c > regpricelists = [select id, Type__c, Start_Date__c, End_Date__c, Price__c, (select id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c from PriceListLines__r
                                                                                                          Order by Start__c) from PriceList__c Where Type__c = 'רגיל'
                                               Order by Start_Date__c DESC
                                              ];
        Map < String, Transaction__c > trans = new Map < String, Transaction__c > ([select id, Date_of_Transaction__c from Transaction__c where RecordType.Name = 'נקודות'
                                                                                    and id in: transids
                                                                                   ]);
        DateTime startDate;
        DateTime endDate;
        Double extraHours;
        Double extraHolidayHours;
        for (Cruise__c crs: newList) {
            Decimal oldpts = crs.Cruise_Points__c;
            crs.Cruise_Points__c = 0;
            system.debug('trans='+trans);
            system.debug('crs='+crs);
            system.debug('crs.Transaction__c='+trans.get(crs.Transaction__c));
            if (trans.containsKey(crs.Transaction__c)) {
                Date dt = Date.newInstance(crs.Start_Date__c.year(), crs.Start_Date__c.month(), crs.Start_Date__c.day());
                //new Points
                Boolean found = false;
                for (PriceList__c pl: dispricelists){
                    system.debug('pl.Start_Date__c=' +pl.Start_Date__c);
                    system.debug('dt='+dt);
                    if (pl.Start_Date__c <= dt && (pl.End_Date__c == null || pl.End_Date__c >= dt)) {
                        found = true;
                        Decimal basePoints = TransactionPoints.getPTS('Club', crs.Boat__c, crs.Holiday__c||dt.toStartOfWeek().daysBetween(dt)==6||dt.toStartOfWeek().daysBetween(dt)==5, pl.PriceListLines__r, pl.Price__c, crs.Start_Date__c, crs.End_Date__c);
                        Decimal adjustment = crs.AddingReducingPoints__c != null ? crs.AddingReducingPoints__c : 0;
                        crs.Cruise_Points__c = basePoints + adjustment;
                        break;
                    }}
                if (!found) {
                    Date dt2 = dt;
                    dt = Date.newInstance(trans.get(crs.Transaction__c).Date_of_Transaction__c.year(), trans.get(crs.Transaction__c).Date_of_Transaction__c.month(), trans.get(crs.Transaction__c).Date_of_Transaction__c.day());
                    for (PriceList__c pl: regpricelists){
                        system.debug('--pl.Start_Date__c='+pl.Start_Date__c);
                        system.debug('--pl.End_Date__c='+pl.End_Date__c);
                        system.debug('--dt='+dt);
                        if (pl.Start_Date__c <= dt && (pl.End_Date__c == null || pl.End_Date__c >= dt)) {
                            found = true;
                            Decimal basePoints = TransactionPoints.getPTS('Club', crs.Boat__c, crs.Holiday__c||dt2.toStartOfWeek().daysBetween(dt2)==6||dt2.toStartOfWeek().daysBetween(dt2)==5, pl.PriceListLines__r, pl.Price__c, crs.Start_Date__c, crs.End_Date__c);
                            Decimal adjustment = crs.AddingReducingPoints__c != null ? crs.AddingReducingPoints__c : 0;
                            crs.Cruise_Points__c = basePoints + adjustment;
                            break;
                        }
                    }
                }
                if(crs.Cruise_Points__c!=oldpts||statchanged.contains(crs.id))    transchanged.add(crs.Transaction__c);
            } else {
                //old hours
                startDate = crs.Start_Date__c;
                endDate = crs.End_Date__c;
                if (crs.Holiday__c) {
                    extraHolidayHours = crs.Hidden_Total_Hours__c;
                    extraHolidayHours = (extraHolidayHours * 150 / 100) - extraHolidayHours;
                    crs.Extra_Hours_Charge__c = extraHolidayHours;
                } else {
                    extraHours = manager.CalculateExtraHours(startDate, endDate);
                    crs.Extra_Hours_Charge__c = extraHours;
                }
            }
        }
        if(transchanged.size()>0)   ID jobID = System.enqueueJob(new TransactionPoints(transchanged));
    }
    public void CalculateExtraHours(Map < Id, Cruise__c > newMap, Map < Id, Cruise__c > oldMap) {
        List < Cruise__c > CruiseUpdateList = new List < Cruise__c > ();
        Set < Id > cruiseIdSet = new Set < Id > ();
        Set <String> statchanged = new Set <String>();
        List < String > cruiseChange = new List < String > {
            'Start_Date__c',
                'End_Date__c',
                'Holiday__c',
                'Status__c',
                'Transaction__c',
                'AddingReducingPoints__c'
                };
                    isChangedHelper.setNewCollection('cruisChange', cruiseChange);
        if (!isChangedHelper.getCollectionChanges('cruisChange').isEmpty()) {
            cruiseIdSet = isChangedHelper.getCollectionChanges('cruisChange');
        }
        for (Id idItem: cruiseIdSet) {
            CruiseUpdateList.add(newMap.get(idItem));
        }
        for(Id id:newMap.keySet())
            if(newMap.get(id).Status__c!=oldMap.get(id).Status__c)
            statchanged.add(id);
        if (!CruiseUpdateList.isEmpty()) {
            this.CalculateExtraHours(CruiseUpdateList,statchanged);
        }
        List <Cruise__c> oldmoved = new List <Cruise__c>();
        for(Id id:newMap.keySet())
            if(newMap.get(id).Transaction__c!=oldMap.get(id).Transaction__c)
            oldmoved.add(oldMap.get(id));
        if(oldmoved.size()>0)   upOldVals(oldmoved);
    }
    public void upOldVals(List <Cruise__c> oldcrs){
        String clubrectype = [select id from RecordType where Name = 'Club'
                              and SobjectType = 'Cruise__c'
                             ].id;
        Set <String> ccmsids = new Set <String>();
        Set <String> transids = new Set <String> ();
        Set <String> transchanged = new Set <String> ();
        for (Cruise__c crs: oldcrs)
            if (crs.Transaction__c != null && crs.RecordTypeid == clubrectype) transids.add(crs.Transaction__c);
        else if(crs.RecordTypeid != clubrectype) ccmsids.add(crs.id);
        Map < String, Transaction__c > trans = new Map < String, Transaction__c > ([select id, Date_of_Transaction__c from Transaction__c where RecordType.Name = 'נקודות'
                                                                                    and id in: transids
                                                                                   ]);
        transchanged.addAll(trans.keySet());
        List <Co_Cruise_Members__c> ccms = [select id,Transaction__c from Co_Cruise_Members__c where Cruise__c in: ccmsids];
        for(Co_Cruise_Members__c ccm:ccms)
            ccm.Cruise__c = null;
        Database.update(ccms,false);
        if(transchanged.size()>0)   ID jobID = System.enqueueJob(new TransactionPoints(transchanged));
    }
    // Method to update noOfSCCountsForSelectedMonth when the cruise status get cancelled.
    // created by Sameer on 15th Dec 2021.
    public void updateNumberOfCount(List<Cruise__c> listOfCruise, map<Id, Cruise__c> mapOfOldCruise){
        try{
            Id recTypeIdEnrichingType = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName().get('Enriching').getRecordTypeId();
            Id recTypeIdFriendsType = Schema.SObjectType.Cruise__c.getRecordTypeInfosByDeveloperName().get('Friends').getRecordTypeId();
            /*System.debug('recTypeIdEnrichingType >>>>>'+recTypeIdEnrichingType + 'recTypeIdFriendsType> '+recTypeIdFriendsType);
            System.debug('listOfCruise >>>>>'+listOfCruise);
            System.debug('mapOfOldCruise >>>>>'+mapOfOldCruise);
            Set<ID> setOfCruiseIds = new Set<ID>();
            for(Cruise__c crus: listOfCruise){
                system.debug('recordTypeId >>>>>>> '+crus.recordTypeId);
                system.debug('Old Cruse Status >>>>> '+mapOfOldCruise.get(crus.Id).Status__c);
                if(crus.Status__c == 'Canceled' && (crus.recordTypeId ==recTypeIdEnrichingType || crus.recordTypeId ==recTypeIdFriendsType) && crus.Status__c != mapOfOldCruise.get(crus.Id).Status__c){
                    setOfCruiseIds.add(crus.Id);
                }
            }
            System.debug('setOfCruiseIds >>>>'+setOfCruiseIds);
            Map<Id, List<Co_Cruise_Members__c>> cruiseCoCruiseMap = new Map<Id, List<Co_Cruise_Members__c>>();
            List<Co_Cruise_Members__c> cruiseAndCocruiseList = [Select Id, Name, noOfSCCountsForSelectedMonth__c, Cruise__r.name, Cruise__r.ID From Co_Cruise_Members__c where Cruise__r.ID in: setOfCruiseIds];
            System.debug('cruiseAndCocruiseList >>>>>'+cruiseAndCocruiseList);
            
            for(Co_Cruise_Members__c coCru : cruiseAndCocruiseList){
                if(!cruiseCoCruiseMap.ContainsKey(coCru.Cruise__r.ID))
                    cruiseCoCruiseMap.put(coCru.Cruise__r.ID, new List<Co_Cruise_Members__c>());
                cruiseCoCruiseMap.get(coCru.Cruise__r.ID).add(coCru);
            }
            System.debug('cruiseCoCruiseMap >>>>>>>'+cruiseCoCruiseMap); 
            List<Co_Cruise_Members__c> coCruiseListToUpdate=new List<Co_Cruise_Members__c>();
            for(ID cru: cruiseCoCruiseMap.keySet())
            {
                List<Co_Cruise_Members__c> newCoCruisList=cruiseCoCruiseMap.get(cru);
                if(newCoCruisList.size() > 0)
                {
                    for(Co_Cruise_Members__c newCoCruise: newCoCruisList)
                    {
                        if(newCoCruise.noOfSCCountsForSelectedMonth__c !=null && newCoCruise.noOfSCCountsForSelectedMonth__c > 0)
                        {   
                            Co_Cruise_Members__c coCruMem = new Co_Cruise_Members__c();
                            coCruMem.Id = newCoCruise.Id;
                            coCruMem.noOfSCCountsForSelectedMonth__c = newCoCruise.noOfSCCountsForSelectedMonth__c -1;
                            coCruiseListToUpdate.add(coCruMem);
                        }
                    }
                }
            }
            System.debug('coCruiseListToUpdate >>>>>'+coCruiseListToUpdate);
            if(coCruiseListToUpdate.size()>0)
                update coCruiseListToUpdate; 
			*/
            if(
                listOfCruise[0].Status__c == 'Canceled' && 
                (listOfCruise[0].recordTypeId == recTypeIdEnrichingType || listOfCruise[0].recordTypeId == recTypeIdFriendsType) && 
                listOfCruise[0].Status__c != mapOfOldCruise.get(listOfCruise[0].Id).Status__c && 
                listOfCruise[0].Start_Date__c != NULL
            ) {
                Date startDate = Date.newInstance(listOfCruise[0].Start_Date__c.year(), listOfCruise[0].Start_Date__c.month(), 1);
                Integer numberOfDays = Date.daysInMonth(startDate.year(), startDate.month());
                Date endDate = Date.newInstance(listOfCruise[0].Start_Date__c.year(), listOfCruise[0].Start_Date__c.month(), numberOfDays);
                List<Co_Cruise_Members__c> cruiseAndCocruiseList = [SELECT Id, noOfSCCountsForSelectedMonth__c FROM Co_Cruise_Members__c WHERE Cruise__r.Start_Date__c >= :startDate AND Cruise__r.Start_Date__c <= :endDate AND (SailType__c='Friends' OR SailType__c='Enriching')];
               /* List<Co_Cruise_Members__c> cruiseAndCocruiseListChild = [SELECT Id, noOfSCCountsForSelectedMonth__c FROM Co_Cruise_Members__c WHERE Cruise__r.Start_Date__c >= :startDate AND Cruise__r.Start_Date__c <= :endDate AND Cruise__c IN : listOfCruise];
                Integer count;
                if(!cruiseAndCocruiseListChild.isEmpty()){
                count = cruiseAndCocruiseListChild.size();
                  }
                 else count=0; */
                
                if(!cruiseAndCocruiseList.isEmpty()) {
                    for(Co_Cruise_Members__c member : cruiseAndCocruiseList) {
                        if(member.noOfSCCountsForSelectedMonth__c == NULL)
                            member.noOfSCCountsForSelectedMonth__c = 0;
                        member.noOfSCCountsForSelectedMonth__c -= 1;
                    }
                    Database.update(cruiseAndCocruiseList, false);
                }
            }
            if (
                listOfCruise[0].Status__c != 'Canceled' && mapOfOldCruise.get(listOfCruise[0].Id).Status__c =='Canceled' &&
                (listOfCruise[0].recordTypeId == recTypeIdEnrichingType || listOfCruise[0].recordTypeId == recTypeIdFriendsType) && 
                listOfCruise[0].Start_Date__c != NULL &&
                firstRun
            ) {
                firstRun = false;
                 Date startDate = Date.newInstance(listOfCruise[0].Start_Date__c.year(), listOfCruise[0].Start_Date__c.month(), 1);
                Integer numberOfDays = Date.daysInMonth(startDate.year(), startDate.month());
                Date endDate = Date.newInstance(listOfCruise[0].Start_Date__c.year(), listOfCruise[0].Start_Date__c.month(), numberOfDays);
                List<Co_Cruise_Members__c> cruiseAndCocruiseList = [SELECT Id, noOfSCCountsForSelectedMonth__c FROM Co_Cruise_Members__c WHERE Cruise__r.Start_Date__c >= :startDate AND Cruise__r.Start_Date__c <= :endDate AND (SailType__c='Friends' OR SailType__c='Enriching')];
               /*  List<Co_Cruise_Members__c> cruiseAndCocruiseListChild = [SELECT Id, noOfSCCountsForSelectedMonth__c FROM Co_Cruise_Members__c WHERE Cruise__r.Start_Date__c >= :startDate AND Cruise__r.Start_Date__c <= :endDate AND Cruise__c IN : listOfCruise];
                Integer count;
                if(!cruiseAndCocruiseListChild.isEmpty()){
                count = cruiseAndCocruiseListChild.size();
                  }
                 else count=0; */
                
                if(!cruiseAndCocruiseList.isEmpty()) {
                    for(Co_Cruise_Members__c member : cruiseAndCocruiseList) {
                        if(member.noOfSCCountsForSelectedMonth__c == NULL)
                            member.noOfSCCountsForSelectedMonth__c = 0;
                        member.noOfSCCountsForSelectedMonth__c += 1;
                    }
                    Database.update(cruiseAndCocruiseList, false);
            }
                }
        }catch(Exception ex){
            System.debug('Occured error is >>>>>>>'+ex.getMessage()+'At line number >>>>>>'+ex.getLineNumber());
        }
    }
    
    // Method to update the available seats in boat when the cruise record is get updated with Enriching or Friends record type
    // created by Sameer on 15th Dec 2021.
 /*   public void updateAvailableSeatsInboat(List<Cruise__c> listOfCruiseForBoatSeat, map<Id,Cruise__c> oldmapValues){
        try{
            Id recTypeIdFriendsType = Schema.SObjectType.Cruise__c.getRecordTypeInfosByName().get('Friends').getRecordTypeId();
            Id recTypeIdEnrichingType = Schema.SObjectType.Cruise__c.getRecordTypeInfosByName().get('Enriching').getRecordTypeId();
            List<Cruise__c> listOfCruise = new List<Cruise__c>();
            List<Cruise__c> listOtherThanFriendOrEnriching = new List<Cruise__c>();
            List<Cruise__c> listOfCruiseToGet = new List<Cruise__c>();
            List<Cruise__c> listOfCruiseToUpdate = new List<Cruise__c>();
            for(Cruise__c crusFrBot: listOfCruiseForBoatSeat){
                if(( (oldmapValues.get(crusFrBot.Id).SCCount__c != crusFrBot.SCCount__c) ) &&  (crusFrBot.recordTypeId ==recTypeIdEnrichingType || crusFrBot.recordTypeId ==recTypeIdFriendsType)){
                                       
                    listOfCruise.add(crusFrBot);
                }
                else if((oldmapValues.get(crusFrBot.Id).maxSeatsFromBoat__c != crusFrBot.maxSeatsFromBoat__c) && (crusFrBot.recordTypeId ==recTypeIdEnrichingType || crusFrBot.recordTypeId ==recTypeIdFriendsType)){
                     listOfCruise.add(crusFrBot);
                    
                }
                
                else if( (oldmapValues.get(crusFrBot.Id).SCCount__c != crusFrBot.SCCount__c) && (crusFrBot.recordTypeId != recTypeIdEnrichingType && crusFrBot.recordTypeId != recTypeIdFriendsType)){
                    listOtherThanFriendOrEnriching.add(crusFrBot);
                }
                else if(((oldmapValues.get(crusFrBot.Id).maxSeatsFromBoat__c != crusFrBot.maxSeatsFromBoat__c) ) && (crusFrBot.recordTypeId != recTypeIdEnrichingType && crusFrBot.recordTypeId != recTypeIdFriendsType)){
                    listOtherThanFriendOrEnriching.add(crusFrBot);
                }
                
               
            }
            if(!listOfCruise.isempty()){
                listOfCruiseToGet = [Select Id,Boat__r.Max_Passenger__c,SCCount__c from Cruise__c where ID IN :listOfCruise];
                for(Cruise__c crs : listOfCruiseToGet){
                    Cruise__c cr = new Cruise__c();
                    cr.Id = crs.Id;
                    if(crs.SCCount__c != null){
                        cr.remainingSeatCalculation__c= (crs.Boat__r.Max_Passenger__c - crs.SCCount__c) -1;
                    }
                    else cr.remainingSeatCalculation__c= (crs.Boat__r.Max_Passenger__c-0) -1;
                    
                    listOfCruiseToUpdate.add(cr);
                }
            }
            else if(!listOtherThanFriendOrEnriching.isEmpty()){
                listOfCruiseToGet = [Select Id,Name,Boat__r.Max_Passenger__c,SCCount__c from Cruise__c where ID IN :listOtherThanFriendOrEnriching];
                for(Cruise__c crs : listOfCruiseToGet){
                    Cruise__c cr = new Cruise__c();
                    cr.Id = crs.Id;
                    if(crs.SCCount__c != null){
                        cr.remainingSeatCalculation__c= (crs.Boat__r.Max_Passenger__c - crs.SCCount__c);
                    }
                    else cr.remainingSeatCalculation__c= (crs.Boat__r.Max_Passenger__c);
                    listOfCruiseToUpdate.add(cr);
                }
            }
            System.debug('listOfCruiseToUpdate >>>>'+listOfCruiseToUpdate);
            if(!listOfCruiseToUpdate.isEmpty() && !Test.isRunningTest()){
                Update listOfCruiseToUpdate; 
            }
        }catch(Exception ex){
            System.debug('Occured error is >>>>>>>'+ex.getMessage()+'At line number >>>>>>'+ex.getLineNumber());
        }
    }
    
     // created by Sameer on 15th Dec 2021.
     // Update the remaingSeatInCruise while creating a new cruise record of Enriching or Friends type.
    public void updateAvailableSeatsInboat(List<Cruise__c> listOfCruiseForBoatSeat){
         try{
            Id recTypeIdFriendsType = Schema.SObjectType.Cruise__c.getRecordTypeInfosByName().get('Friends').getRecordTypeId();
            Id recTypeIdEnrichingType = Schema.SObjectType.Cruise__c.getRecordTypeInfosByName().get('Enriching').getRecordTypeId();
             List<Cruise__c> newListCruiseToUpdate = new List<Cruise__c>();
             List<Cruise__c> newListCruise = [Select Id,RecordTypeId,SCCount__c,remainingSeatCalculation__c,Boat__r.Max_Passenger__c From Cruise__c where ID IN :listOfCruiseForBoatSeat];
             for(Cruise__c crusFrBot: newListCruise){
                 if(crusFrBot.RecordTypeId == recTypeIdFriendsType || crusFrBot.RecordTypeId == recTypeIdEnrichingType){
                     if(crusFrBot.Boat__c != null){
                         crusFrBot.remainingSeatCalculation__c = crusFrBot.Boat__r.Max_Passenger__c -((crusFrBot.SCCount__c != null)? crusFrBot.SCCount__c : 0) -1;
                         newListCruiseToUpdate.add(crusFrBot);
                     }
                 }
                 else {
                      if(crusFrBot.Boat__c != null){
                         crusFrBot.remainingSeatCalculation__c = crusFrBot.Boat__r.Max_Passenger__c -((crusFrBot.SCCount__c != null)? crusFrBot.SCCount__c : 0);
                         newListCruiseToUpdate.add(crusFrBot);
                      }
                 }
                 
             }
             if(!newListCruiseToUpdate.isEmpty() && !Test.isRunningTest()){
                 update newListCruiseToUpdate;
             }
         
         }
        
        catch(Exception ex){
             System.debug('Occured error is >>>>>>>'+ex.getMessage()+'At line number >>>>>>'+ex.getLineNumber());
        }
    } */
    
    public class RecordTypeNotExistException extends Exception {}
}