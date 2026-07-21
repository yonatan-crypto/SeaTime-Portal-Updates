public class BoatsSchedulerService {
    private Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

    private Map<String, String> headers = ApexPages.currentPage().getHeaders();
    private Map<String, String> param = ApexPages.currentPage().getParameters();
    private String origin = headers.get('Origin');

    public String response { get; set; }

    public BoatsSchedulerService() {}
    public void action() {
        if (isSandbox && origin != null) {
            headers.put('Access-Control-Allow-Origin', origin);
            headers.put('Access-Control-Allow-Credentials', 'true');
        }

        if (param.containsKey('loadResources')) {
            response = JSON.serialize([SELECT Id, Name FROM Boats__c Where Active__c=true ORDER BY BoatsSchedulerOrder__c]);

        } else if (param.containsKey('loadEvents')) {
            // valueOf is required in order to handle timezone
            Date start = Date.valueOf(param.get('start')).addDays(-1);// + ' 00:00:00');
            Date endd = Date.valueOf(param.get('end')).addDays(1);// + ' 00:00:00');
            response = JSON.serialize(
                [SELECT 
                    Id, Name, Start_Date__c, End_Date__c, Status__c, Boat__c,
                    RecordType.Name, Guide__r.Name, Guide__r.Employee_Phone__c,
                    AccountName__r.Name, AccountName__r.Phone,
                    Cruise_Purpose__c,
                    Co_Cruise__c,
                    Type2__c,
                    Subject__c,
                    Additional_Info__c,
                    Payment_Required__c,
                    Decline_Reason__c,
                    AccountName__r.Email__c,
                    Marina__c,
                    pier__c,
                    key_location__c,
                    information__c,
                    Hidden_Total_Hours__c,
                    Hidden_Additional_Hours__c,
                    Total_Cruise_of_Transaction__c,
                    Holiday__c,
                    Extra_Hours_Charge__c,
                    skill_level__c
                FROM Cruise__c WHERE
                    Status__c!='Canceled' AND
                    ((Start_Date__c  > :start AND Start_Date__c  < :endd) OR
                     (End_Date__c    > :start AND End_Date__c    < :endd) OR
                     (Start_Date__c  < :start AND End_Date__c    > :endd))
                ]
            );

        } else if (param.containsKey('updateEvent')) {
            update new Cruise__c(
                Id=param.get('id'),
                Start_Date__c=Datetime.valueOf(param.get('start')),
                End_Date__c=Datetime.valueOf(param.get('end'))
            );
        }
    }
}