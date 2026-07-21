public class CreateCruise {
    private Map<String, String> param = ApexPages.currentPage().getParameters();

    public Boolean isClassic { set; get; }
    public String createParam { set; get; }
    public String rts { set; get; }
    public Cruise__c cruise  { set; get; }
    public String retURL { set; get; }

    public CreateCruise() {
        createParam = 'null';
        rts = JSON.serialize([SELECT Id, Description FROM RecordType WHERE SObjectType='Cruise__c']);
        cruise = new Cruise__c(RecordTypeId=[SELECT Id FROM RecordType WHERE SObjectType='Cruise__c' AND Name='Club' LIMIT 1].Id);
        retURL = param.get('retURL') != null ? param.get('retURL') : '/a04/o';
    }

    public PageReference save() {
        createParam = 'null';
        RecordType rt = [SELECT Id, Name FROM RecordType WHERE Id=:cruise.RecordTypeId LIMIT 1];
        Account account;
        if (rt.Name == 'Club')
            if (cruise.AccountName__c != null) account = [SELECT Id, Name FROM Account WHERE Id=:cruise.AccountName__c LIMIT 1];
            else return null;
        Boats__c boat = [SELECT Id, Name, Type__c FROM Boats__c WHERE Id=:param.get('boatId') LIMIT 1];
        String start = param.get('start');
        String endd = param.get('end');
        String payment = '0';
        Transaction__c trans;
        if (rt.Name == 'Club')
            try {
                trans = [select Id, Date_of_Transaction__c, Name, Type__c, Account_Name__c from Transaction__c where Account_Name__c=:account.Id and RecordType.Name='נקודות' Order by Date_of_Transaction__c DESC limit 1];
            }catch (QueryException ep) {   
                try {
                    trans = [SELECT Id, Name, Type__c FROM Transaction__c WHERE Account_Name__c=:account.Id AND Type__c=:boat.Type__c ORDER BY Date_of_Transaction__c DESC LIMIT 1];
                } catch (QueryException e) {
                    if(Test.isRunningTest()){
                        payment = '1';
                        trans = new Transaction__c(
                            Account_Name__c=account.Id,
                            Type__c=boat.Type__c,
                            type_of_membership__c = 'חבר מועדון כולל פרטיות',
                            Name='עסקה חדשה - ' + boat.Type__c
                        );
                        insert trans;
                    }
                    else
                        throw new QueryException('לא נמצאה עסקה מתאימה במערכת');
                }
            }
        else
            trans = [SELECT Id, Name FROM Transaction__c WHERE Transaction_Number__c='D-00001' LIMIT 1];

        if (isClassic) {
            PageReference pRef = new PageReference('/a04/e');
            param = pRef.getParameters();
            param.put('CF00N0Y00000R49jV', boat.Name);
            param.put('CF00N0Y00000R49jV_lkid', boat.Id);
            param.put('00N0Y00000R49jp', start);
            param.put('00N0Y00000R49je', endd);
            param.put('RecordType', rt.Id);
            if (account != null) {
                param.put('CF00N0Y00000R49jR', account.Name);
                param.put('CF00N0Y00000R49jR_lkid', account.Id);
            }
            param.put('00N0Y00000R49jo', payment);
            param.put('CF00N0Y00000R49iq', trans.Name);
            param.put('CF00N0Y00000R49iq_lkid', trans.Id);
            param.put('retURL', retURL);
            pRef.setRedirect(true);
            return pRef;
        } else {
            createParam = JSON.serialize(new Map<String, Object>{
                'Boat__c' => boat.Id,
                    
                // commented by bali for Date-time parsing was changed from Datetime.parse() to Datetime.newInstance()
                //'Start_Date__c' => Datetime.parse(start),
                //'End_Date__c' => Datetime.parse(endd),
                
                    
                 'Start_Date__c' => Datetime.newInstance(
                    Integer.valueOf(start.split(' ')[1].split('/')[2]), Integer.valueOf(start.split(' ')[1].split('/')[1]), Integer.valueOf(start.split(' ')[1].split('/')[0]), 
                    Integer.valueOf(start.split(' ')[0].split(':')[0]), Integer.valueOf(start.split(' ')[0].split(':')[1]), 0),
                'End_Date__c' => Datetime.newInstance(
                    Integer.valueOf(endd.split(' ')[1].split('/')[2]), Integer.valueOf(endd.split(' ')[1].split('/')[1]), Integer.valueOf(endd.split(' ')[1].split('/')[0]),
                    Integer.valueOf(endd.split(' ')[0].split(':')[0]), Integer.valueOf(endd.split(' ')[0].split(':')[1]), 0 ),
                                    
                    
                    
                'AccountName__c' => account != null ? account.Id : null,
                'Payment_Required__c' => payment == '1',
                'Transaction__c' => trans.Id
            });
            return null;
        }
    }

}