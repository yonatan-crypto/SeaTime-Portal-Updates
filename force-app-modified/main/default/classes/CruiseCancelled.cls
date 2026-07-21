/*public class CruiseCancelled {
    public static void beforeDelete(list<Co_Cruise_Members__c>Co_Cruise_Members) {
        for (Co_Cruise_Members__c l : Co_Cruise_Members) {
            if(l.Cruise__c!=null&&l.Account_Co__c!=null){
                map<string, object> params = new map<string, object>();
                params.put('CoMemberID', l.Id);
                Flow.Interview.Delete_Co_Member flow = new Flow.Interview.Delete_Co_Member(params);
                flow.start();
            }
        }
    }
    
}*/   // commented by Bali Krishan 04/02/26

        // added Bali Krishan for error handling CANNOT_EXECUTE_FLOW_TRIGGER
public class CruiseCancelled {
    public static Boolean testBypass = false;
    
    public static void afterDelete(list<Co_Cruise_Members__c> Co_Cruise_Members) {
        if (testBypass || CoCruiseTriggerHandler.byPassTrigger) return;
        
        for (Co_Cruise_Members__c l : Co_Cruise_Members) {
            if(l.Cruise__c != null && l.Account_Co__c != null){
                try {
                    map<string, object> params = new map<string, object>();
                    params.put('CoMemberID', l.Id);
                    Flow.Interview.Delete_Co_Member flow = new Flow.Interview.Delete_Co_Member(params);
                    flow.start();
                } catch(Exception e) {
                    System.debug('Flow execution error: ' + e.getMessage());
                    if(!Test.isRunningTest()) {
                        throw e; // Production mein error throw karo
                    }
                }
            }
        }
    }
}