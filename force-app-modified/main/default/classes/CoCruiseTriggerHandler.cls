@suppresswarnings('pmd.CognitiveComplexity')
public without sharing class CoCruiseTriggerHandler {
  public static Boolean byPassTrigger = false;
  public static void handleCoCruiseTrigger(
    System.TriggerOperation operationType
  ) {
    if (byPassTrigger) {
      return;
    }

    switch on operationType {
      when BEFORE_INSERT {
        updatePointsOnInsert(Trigger.New);
      }
      when BEFORE_UPDATE {
        updatePointsOnUpdate(Trigger.New, Trigger.OldMap);
      }
      when BEFORE_DELETE {
        updatePointsOnDelete(Trigger.Old);
      }
        // added Bali Krishan for error handling CANNOT_EXECUTE_FLOW_TRIGGER
      when AFTER_DELETE {
          CruiseCancelled.afterDelete(Trigger.Old);
      }
    }
  }

  @suppresswarnings('pmd.NcssMethodCount')
  private static void updatePointsOnInsert(
    List<Co_Cruise_Members__c> cruiseMembersList
  ) {
   
    //manage connect point transaction
    Set<String> accids = new Set<String>();
    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
      if (ccm.Transaction__c == null && ccm.Account_Co__c != null) {
        accids.add(ccm.Account_Co__c);
      }
    }

    List<Transaction__c> pointsTrans = [
      SELECT Id, Date_of_Transaction__c, Name, Type__c, Account_Name__c, Active__c
      FROM Transaction__c
      WHERE Account_Name__c IN :accids AND RecordType.Name = 'נקודות'
      ORDER BY Account_Name__c, Active__c DESC, Date_of_Transaction__c DESC
    ];
    Map<String, String> transbyacc = new Map<String, String>();
    for (Transaction__c tran : pointsTrans) {
      if (!transbyacc.containsKey(tran.Account_Name__c)) {
        transbyacc.put(tran.Account_Name__c, tran.id);
      }
    }
      
    for (Co_Cruise_Members__c ccm : cruiseMembersList)
      if (
        ccm.Transaction__c == null &&
        ccm.Account_Co__c != null &&
        transbyacc.containsKey(ccm.Account_Co__c)
      ) {
        ccm.Transaction__c = transbyacc.get(ccm.Account_Co__c);
      }

    //add all cruises
    Map<String, String> crsbytran = new Map<String, String>();
    Set<String> transchanged = new Set<String>();

    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
      if (ccm.Cruise__c != null && ccm.Transaction__c != null) {
        crsbytran.put(ccm.Transaction__c, ccm.Cruise__c);
      }

      if (ccm.Transaction__c != null) {
        transchanged.add(ccm.Transaction__c);
      }
    }

    //query
    List<PriceList__c> dispricelists = [
      SELECT
        id,
        Type__c,
        Start_Date__c,
        End_Date__c,
        Price__c,
        (
          SELECT id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c
          FROM PriceListLines__r
          ORDER BY Start__c
        )
      FROM PriceList__c
      WHERE Type__c = 'מבצע'
      ORDER BY Start_Date__c DESC
    ];
    List<PriceList__c> regpricelists = [
      SELECT
        id,
        Type__c,
        Start_Date__c,
        End_Date__c,
        Price__c,
        (
          SELECT id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c
          FROM PriceListLines__r
          ORDER BY Start__c
        )
      FROM PriceList__c
      WHERE Type__c = 'רגיל'
      ORDER BY Start_Date__c DESC
    ];
    Map<String, Transaction__c> trans = new Map<String, Transaction__c>(
      [
        SELECT Id, Date_of_Transaction__c, Name, Type__c, Account_Name__c
        FROM Transaction__c
        WHERE id IN :crsbytran.keySet() AND RecordType.Name = 'נקודות'
        ORDER BY Account_Name__c, Date_of_Transaction__c DESC
      ]
    );
    Map<String, Cruise__c> crs = new Map<String, Cruise__c>(
      [
        SELECT id, Boat__c, RecordType.Name, Holiday__c, Start_Date__c, End_Date__c, type_of_enriching__c 
        FROM Cruise__c 
        WHERE id IN :crsbytran.values()
      ]
    );

    // Get Student status from Accounts
    Set<Id> allAccIds = new Set<Id>();
    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
        if (ccm.Account_Co__c != null) allAccIds.add(ccm.Account_Co__c);
    }
    Map<Id, Account> studentAccMap = new Map<Id, Account>([SELECT Id, StudentMeshit30__c FROM Account WHERE Id IN :allAccIds]);

    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
      ccm.Cruise_Points__c = 0;
      
      // NEW LOGIC: If student, they pay 0 points ONLY for School/Theory cruises
      Account memberAcc = studentAccMap.get(ccm.Account_Co__c);
      if (memberAcc != null && memberAcc.StudentMeshit30__c == true) {
          Cruise__c cruiseRecord = crs.get(ccm.Cruise__c);
          if (cruiseRecord != null) {
              String rtName = cruiseRecord.RecordType.Name;
              String typeOfEnriching = cruiseRecord.type_of_enriching__c;
              String rawType = typeOfEnriching != null ? typeOfEnriching.trim().toLowerCase() : '';
              Boolean isSchoolOrTheory = (rtName == 'Enriching' || rtName == 'העשרה') && 
                  (rawType == 'בית ספר' || rawType == 'school' || rawType == 'lesson' || rawType == 'תאוריה' || rawType == 'theory');
              
              if (isSchoolOrTheory) {
                  ccm.Cruise_Points__c = 0;
                  continue; 
              }
          }
      }

      if (
        ccm.Cruise__c != null &&
        ccm.Transaction__c != null &&
        crs.containsKey(ccm.Cruise__c) &&
        trans.containsKey(ccm.Transaction__c)
      ) {
        Date dt = Date.newInstance(
          crs.get(ccm.Cruise__c).Start_Date__c.year(),
          crs.get(ccm.Cruise__c).Start_Date__c.month(),
          crs.get(ccm.Cruise__c).Start_Date__c.day()
        );
        Boolean found = false;
        for (PriceList__c pl : dispricelists) {
          if (
            pl.Start_Date__c <= dt &&
            (pl.End_Date__c == null ||
            pl.End_Date__c >= dt)
          ) {
            found = true;
            ccm.Cruise_Points__c = TransactionPoints.getPTS(
              crs.get(ccm.Cruise__c).RecordType.Name,
              crs.get(ccm.Cruise__c).Boat__c,
              crs.get(ccm.Cruise__c).Holiday__c,
              pl.PriceListLines__r,
              pl.Price__c,
              crs.get(ccm.Cruise__c).Start_Date__c,
              crs.get(ccm.Cruise__c).End_Date__c
            );
            break;
          }
        }
        if (!found) {
          dt = Date.newInstance(
            trans.get(ccm.Transaction__c).Date_of_Transaction__c.year(),
            trans.get(ccm.Transaction__c).Date_of_Transaction__c.month(),
            trans.get(ccm.Transaction__c).Date_of_Transaction__c.day()
          );
          for (PriceList__c pl : regpricelists) {
            if (
              pl.Start_Date__c <= dt &&
              (pl.End_Date__c == null ||
              pl.End_Date__c >= dt)
            ) {
              found = true;
              ccm.Cruise_Points__c = TransactionPoints.getPTS(
                crs.get(ccm.Cruise__c).RecordType.Name,
                crs.get(ccm.Cruise__c).Boat__c,
                crs.get(ccm.Cruise__c).Holiday__c,
                pl.PriceListLines__r,
                pl.Price__c,
                crs.get(ccm.Cruise__c).Start_Date__c,
                crs.get(ccm.Cruise__c).End_Date__c
              );
              break;
            }
          }
        }
      }
    }
    
    if (transchanged.size() > 0) {
      ID jobID = System.enqueueJob(new TransactionPoints(transchanged));
    }

  }

  @suppresswarnings('pmd.NcssMethodCount')
  private static void updatePointsOnUpdate(
    List<Co_Cruise_Members__c> cruiseMembersList,
    Map<Id, SObject> cruiseMembersMap
  ) {
    //manage connect point transaction
    Set<String> accids = new Set<String>();
    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
      if (
        ccm.Transaction__c == null &&
        ccm.Account_Co__c != null &&
        (((Co_Cruise_Members__c) (cruiseMembersMap.get(ccm.id)))
          .Account_Co__c != ccm.Account_Co__c)
      ) {
        accids.add(ccm.Account_Co__c);
      }
    }

    List<Transaction__c> pointsTrans = [
      SELECT Id, Date_of_Transaction__c, Name, Type__c, Account_Name__c, Active__c
      FROM Transaction__c
      WHERE Account_Name__c IN :accids AND RecordType.Name = 'נקודות'
      ORDER BY Account_Name__c, Active__c DESC, Date_of_Transaction__c DESC
    ];
    Map<String, String> transbyacc = new Map<String, String>();
    for (Transaction__c tran : pointsTrans) {
      if (!transbyacc.containsKey(tran.Account_Name__c)) {
        transbyacc.put(tran.Account_Name__c, tran.id);
      }
    }

    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
      if (
        ccm.Transaction__c == null &&
        ccm.Account_Co__c != null &&
        transbyacc.containsKey(ccm.Account_Co__c)
      ) {
        ccm.Transaction__c = transbyacc.get(ccm.Account_Co__c);
      }
    }

    //add all cruises
    Map<String, String> crsbytran = new Map<String, String>();
    Set<String> transchanged = new Set<String>();

    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
      if (ccm.Cruise__c != null && ccm.Transaction__c != null) {
        crsbytran.put(ccm.Transaction__c, ccm.Cruise__c);
      }

      Co_Cruise_Members__c oldccm = (Co_Cruise_Members__c) (cruiseMembersMap.get(
        ccm.id
      ));
      if (
        oldccm.Cruise__c != ccm.Cruise__c ||
        oldccm.Transaction__c != ccm.Transaction__c ||
        oldccm.Status__c != ccm.Status__c
      ) {
        if (oldccm.Transaction__c != null) {
          transchanged.add(oldccm.Transaction__c);
        }

        if (ccm.Transaction__c != null) {
          transchanged.add(ccm.Transaction__c);
        }
      }
    }
    //query
    List<PriceList__c> dispricelists = [
      SELECT
        id,
        Type__c,
        Start_Date__c,
        End_Date__c,
        Price__c,
        (
          SELECT id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c
          FROM PriceListLines__r
          ORDER BY Start__c
        )
      FROM PriceList__c
      WHERE Type__c = 'מבצע'
      ORDER BY Start_Date__c DESC
    ];
    List<PriceList__c> regpricelists = [
      SELECT
        id,
        Type__c,
        Start_Date__c,
        End_Date__c,
        Price__c,
        (
          SELECT id, Start__c, Type__c, Boat__c, Price__c, HPrice__c, Global__c
          FROM PriceListLines__r
          ORDER BY Start__c
        )
      FROM PriceList__c
      WHERE Type__c = 'רגיל'
      ORDER BY Start_Date__c DESC
    ];
    Map<String, Transaction__c> trans = new Map<String, Transaction__c>(
      [
        SELECT Id, Date_of_Transaction__c, Name, Type__c, Account_Name__c
        FROM Transaction__c
        WHERE id IN :crsbytran.keySet() AND RecordType.Name = 'נקודות'
        ORDER BY Account_Name__c, Date_of_Transaction__c DESC
      ]
    );
    Map<String, Cruise__c> crs = new Map<String, Cruise__c>(
      [
        SELECT id, Boat__c, RecordType.Name, Holiday__c, Start_Date__c, End_Date__c, type_of_enriching__c 
        FROM Cruise__c 
        WHERE id IN :crsbytran.values()
      ]
    );

    // Get Student status from Accounts
    Set<Id> allAccIdsUpdate = new Set<Id>();
    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
        if (ccm.Account_Co__c != null) allAccIdsUpdate.add(ccm.Account_Co__c);
    }
    Map<Id, Account> studentAccMapUpdate = new Map<Id, Account>([SELECT Id, StudentMeshit30__c FROM Account WHERE Id IN :allAccIdsUpdate]);

    for (Co_Cruise_Members__c ccm : cruiseMembersList) {
     // ccm.Cruise_Points__c = 0;
     
      // NEW LOGIC: If student, they pay 0 points ONLY for School/Theory cruises
      Account memberAcc = studentAccMapUpdate.get(ccm.Account_Co__c);
      if (memberAcc != null && memberAcc.StudentMeshit30__c == true) {
          Cruise__c cruiseRecord = crs.get(ccm.Cruise__c);
          if (cruiseRecord != null) {
              String rtName = cruiseRecord.RecordType.Name;
              String typeOfEnriching = cruiseRecord.type_of_enriching__c;
              String rawType = typeOfEnriching != null ? typeOfEnriching.trim().toLowerCase() : '';
              Boolean isSchoolOrTheory = (rtName == 'Enriching' || rtName == 'העשרה') && 
                  (rawType == 'בית ספר' || rawType == 'school' || rawType == 'lesson' || rawType == 'תאוריה' || rawType == 'theory');
              
              if (isSchoolOrTheory) {
                  ccm.Cruise_Points__c = 0;
                  continue; 
              }
          }
      }

      if (
        ccm.Cruise__c != null &&
        ccm.Transaction__c != null &&
        crs.containsKey(ccm.Cruise__c) &&
        trans.containsKey(ccm.Transaction__c)
      ) {
        Date dt = Date.newInstance(
          crs.get(ccm.Cruise__c).Start_Date__c.year(),
          crs.get(ccm.Cruise__c).Start_Date__c.month(),
          crs.get(ccm.Cruise__c).Start_Date__c.day()
        );
        Boolean found = false;
        for (PriceList__c pl : dispricelists) {
          if (
            pl.Start_Date__c <= dt &&
            (pl.End_Date__c == null ||
            pl.End_Date__c >= dt)
          ) {
            found = true;
            ccm.Cruise_Points__c = TransactionPoints.getPTS(
              crs.get(ccm.Cruise__c).RecordType.Name,
              crs.get(ccm.Cruise__c).Boat__c,
              crs.get(ccm.Cruise__c).Holiday__c,
              pl.PriceListLines__r,
              pl.Price__c,
              crs.get(ccm.Cruise__c).Start_Date__c,
              crs.get(ccm.Cruise__c).End_Date__c
            );
            break;
          }
        }
        if (!found) {
          dt = Date.newInstance(
            trans.get(ccm.Transaction__c).Date_of_Transaction__c.year(),
            trans.get(ccm.Transaction__c).Date_of_Transaction__c.month(),
            trans.get(ccm.Transaction__c).Date_of_Transaction__c.day()
          );
          for (PriceList__c pl : regpricelists) {
            if (
              pl.Start_Date__c <= dt &&
              (pl.End_Date__c == null ||
              pl.End_Date__c >= dt)
            ) {
              found = true;
              ccm.Cruise_Points__c = TransactionPoints.getPTS(
                crs.get(ccm.Cruise__c).RecordType.Name,
                crs.get(ccm.Cruise__c).Boat__c,
                crs.get(ccm.Cruise__c).Holiday__c,
                pl.PriceListLines__r,
                pl.Price__c,
                crs.get(ccm.Cruise__c).Start_Date__c,
                crs.get(ccm.Cruise__c).End_Date__c
              );
              break;
            }
          }
        }
      }
    }
    
    if (transchanged.size() > 0) {
      ID jobID = System.enqueueJob(new TransactionPoints(transchanged));
    }
  }

  private static void updatePointsOnDelete(
    List<Co_Cruise_Members__c> oldCruiseMembersList
  ) {
    Set<String> transids = new Set<String>();
    for (Co_Cruise_Members__c ccm : oldCruiseMembersList) {
      if (ccm.Transaction__c != null) {
        transids.add(ccm.Transaction__c);
      }
    }

    Map<String, Transaction__c> trans = new Map<String, Transaction__c>(
      [
        SELECT id, Date_of_Transaction__c
        FROM Transaction__c
        WHERE RecordType.Name = 'נקודות' AND id IN :transids
      ]
    );
    if (trans.keySet().size() > 0) {
      ID jobID = System.enqueueJob(new TransactionPoints(trans.keySet()));
    }
  }
}