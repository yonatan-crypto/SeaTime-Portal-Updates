public without sharing class SeatimeSchedulerBookingController {
  @suppresswarnings('pmd.CognitiveComplexity')
  @AuraEnabled
  public static WrapperController seaTimeSchedulerBooking(String accountId) {
    try {
      System.debug('accountId : ' + accountId);
      WrapperController obj = new WrapperController();

      Account acc = [
        SELECT Id, StudentMeshit30__c, Student7Meter__c
        FROM Account
        WHERE Id = :accountId
        WITH SYSTEM_MODE
      ];

      List<Transaction__c> transactions = [
        SELECT Id, Active__c, Points_Balance__c
        FROM Transaction__c
        WHERE
          Account_Name__c = :accountId
          AND Active__c = TRUE
          AND Points_Balance__c > 30
        WITH SYSTEM_MODE
      ];

      Map<Id, Co_Cruise_Members__c> subCustomerMap = new Map<Id, Co_Cruise_Members__c>(
        [
          SELECT id, Account_Co__c, Cruise__c
          FROM Co_Cruise_Members__c
          WHERE Account_Co__c = :accountId AND Cruise__c != NULL
          WITH SYSTEM_MODE
        ]
      );
      Set<Id> saildIds = new Set<Id>();

      for (Co_Cruise_Members__c c : subCustomerMap.values()) {
        saildIds.add(c.Cruise__c);
      }

      String cruiseListQuery = 'SELECT id, Name, Status__c, Additional_Info__c, DATE__c, Guide__c, RemaingSeatsInBoat__c, Start_Date__c, End_Date__c, AccountName__c, recordtype.name, AccountName__r.Name, Boat__c, Boat__r.Name, toLabel(Boat__r.Type__c), SailStartMonthYear__c, Boat_Name__c FROM Cruise__c WHERE';
      if ((transactions.size() > 0) || acc.StudentMeshit30__c == true) {
        cruiseListQuery += ' ((RecordType.name = \'Friends\' OR RecordType.name = \'Enriching\'';
        if ((transactions.size() > 0)) {
          cruiseListQuery += ' OR RecordType.name = \'Certification\'';
          if (acc.Student7Meter__c == true) {
            cruiseListQuery += ' OR (RecordType.name = \'Course\' AND Course_Type__c = \'קורס 7 מטר\'))) AND Start_Date__c >= :todayDate AND End_Date__c >= :todayDate AND Status__c != \'Canceled\' AND IsPrivateCourse__c = FALSE ORDER BY Start_Date__c ASC';
          } else {
            cruiseListQuery += ')) AND Start_Date__c >= :todayDate AND End_Date__c >= :todayDate AND Status__c != \'Canceled\' AND IsPrivateCourse__c = FALSE ORDER BY Start_Date__c ASC';
          }
        } else {
          if (acc.Student7Meter__c == true) {
            cruiseListQuery += ' OR (RecordType.name = \'Course\' AND Course_Type__c = \'קורס 7 מטר\')) AND For_Club_Members_Only__c = FALSE)  AND Start_Date__c >= :todayDate AND End_Date__c >= :todayDate AND Status__c != \'Canceled\' AND IsPrivateCourse__c = FALSE ORDER BY Start_Date__c ASC';
          } else {
            cruiseListQuery += ') AND For_Club_Members_Only__c = FALSE) AND Start_Date__c >= :todayDate AND End_Date__c >= :todayDate AND Status__c != \'Canceled\' AND IsPrivateCourse__c = FALSE ORDER BY Start_Date__c ASC';
          }
        }
      } else if (acc.Student7Meter__c == true) {
        cruiseListQuery += ' ((RecordType.name = \'Course\' AND Course_Type__c = \'קורס 7 מטר\') AND For_Club_Members_Only__c = FALSE) AND Start_Date__c >= :todayDate AND End_Date__c >= :todayDate AND Status__c != \'Canceled\' AND IsPrivateCourse__c = FALSE ORDER BY Start_Date__c ASC';
      } else {
        cruiseListQuery = '';
      }

      System.debug('CruiseListQuery : ' + cruiseListQuery);

      if (cruiseListQuery != '') {
        WrapperController wrappedObj = getWrappedObj(
          cruiseListQuery,
          saildIds,
          obj
        );
        return wrappedObj;
      }
    } catch (exception e) {
      system.debug('seaTimeSchedulerBooking Message::' + e.getMessage());
      system.debug('seaTimeSchedulerBooking Line::' + e.getLineNumber());
    }
    return null;
  }

  private static WrapperController getWrappedObj(
    String cruiseListQuery,
    Set<Id> saildIds,
    WrapperController obj
  ) {
    Date todayDate = Date.today();
    List<Cruise__c> cruiseList = Database.query(cruiseListQuery);
    system.debug(
      ':::::::::::::::::::::::::************************************::::::::::::::::::::::::::: '
    );

    system.debug('sailMap::: ' + cruiseList);

    List<InnerWrapper> wrapList = new List<InnerWrapper>();
    System.debug('saildIds::' + saildIds);
    for (Cruise__c cruise : cruiseList) {
      System.debug('cruside id ' + cruise.Id);
      InnerWrapper wrp = new InnerWrapper();
      wrp.name = cruise.Name;
      wrp.sailId = cruise.Id;
      wrp.status = cruise.Status__c;
      wrp.additionalInfo = cruise.Additional_Info__c;
      wrp.sailStartMonthYear = cruise.SailStartMonthYear__c;
      wrp.remaingSeatsInBoat = Integer.valueOf(cruise.RemaingSeatsInBoat__c);
      String newDate = '';
      String newDate1 = '';
      String strDate = '';
      String strtTime = '';
      String endTime = '';
      if (cruise.Start_Date__c != null) {
        newDate = String.valueOf(cruise.Start_Date__c);
        strDate = newDate.split(' ')[0];
        System.debug('strDate::' + strDate);
        strtTime = newDate.split(' ')[1];
        System.debug('dstrtTime-->?' + strtTime);
      }
      if (cruise.End_Date__c != null) {
        newDate1 = String.valueOf(cruise.End_Date__c);
        System.debug('newDate::' + newDate1);
        endTime = newDate1.split(' ')[1];
        System.debug('dstrtTime-->?' + endTime);
      }
      String dateFormatString = 'dd-MM-yyyy';
      Date d2 = Date.valueOf(strDate);
      Datetime dt = Datetime.newInstance(d2.year(), d2.month(), d2.day());
      String stDt = dt.format(dateFormatString);
      wrp.startDate = stDt;
      wrp.startTime = strtTime.split(':')[0] + ':' + strtTime.split(':')[1];
      wrp.endTime = endTime.split(':')[0] + ':' + endTime.split(':')[1];
      wrp.recordTypeId = cruise.RecordTypeId;
      wrp.boat = cruise.Boat__c;
      wrp.boatName = cruise.Boat__r.Name;
      wrp.boatType = cruise.Boat__r.Type__c;
      wrp.recordType = cruise.recordtype.name;
      if (saildIds.contains(cruise.Id)) {
        wrp.bookingStatus = true;
      } else {
        wrp.bookingStatus = false;
      }
      System.debug('wrp::' + wrp);
      wrapList.add(wrp);
    }
    obj.innerWrp = wrapList;
    System.debug('obj::' + obj);
    return obj;
  }

  public class WrapperController {
    @AuraEnabled
    public List<InnerWrapper> innerWrp { get; set; }
  }

  public class InnerWrapper {
    @auraEnabled
    public Id sailId { get; set; }
    @auraEnabled
    public String name { get; set; }
    @auraEnabled
    public String sailStartMonthYear { get; set; }
    @auraEnabled
    public String status { get; set; }
    @auraEnabled
    public String additionalInfo { get; set; }
    @auraEnabled
    public Integer remaingSeatsInBoat { get; set; }
    @auraEnabled
    public String startDate { get; set; }
    @auraEnabled
    public String startTime { get; set; }
    @auraEnabled
    public String endTime { get; set; }
    @auraEnabled
    public Id recordTypeId { get; set; }
    @auraEnabled
    public Id boat { get; set; }
    @auraEnabled
    public String boatName { get; set; }
    @auraEnabled
    public String boatType { get; set; }
    @AuraEnabled
    public Boolean bookingStatus { get; set; }
    @AuraEnabled
    public String recordType { get; set; }
  }

  @AuraEnabled
  public static String insertSubCustomers(
    String sailId,
    String sailStartMonthYear,
    String accountId
  ) {
    try {
      system.debug('sailId:: ' + sailId);
      System.debug('AccountId-->' + accountId);
      System.debug('sailStartMonthYear-->' + sailStartMonthYear);

      AggregateResult[] groupedResults = [
        SELECT Count(Id) counts
        FROM Co_Cruise_Members__c
        WHERE
          Account_Co__c = :accountId
          AND (SailType__c = 'Friends'
          OR SailType__c = 'Enriching'
          OR SailType__c = 'Course'
          OR SailType__c = 'Certification')
          AND Status__c != 'Canceled'
          AND SailStartMonthYear__c = :sailStartMonthYear
        WITH SYSTEM_MODE
      ];
      Integer noOfSCCountsForSelectedMonth = 0;
      for (AggregateResult ar : groupedResults) {
        System.debug('noOfSCCountsForSelectedMonth' + ar.get('counts'));
        noOfSCCountsForSelectedMonth = Integer.valueOf(ar.get('counts'));
      }

      if (noOfSCCountsForSelectedMonth >= 6) {
        System.debug('Inside::::');
        return 'לא ניתן להצטרף להפלגה נוספת, מאחר ונרשמת כבר ל-6 הפלגות החודש. לשאלות נא להתקשר למשרד 037260500';
      } else {
        Co_Cruise_Members__c obj = new Co_Cruise_Members__c();
        obj.Cruise__c = sailId;
        obj.Account_Co__c = AccountId;

        insert as system obj;
        System.debug('obj' + obj);
        return '! נרשמת בהצלחה להפלגה';
      }
    } catch (exception e) {
      system.debug('insertSubCustomer Message::' + e.getMessage());
      system.debug('insertSubCustomer Line::' + e.getLineNumber());
      return null;
    }
  }
}