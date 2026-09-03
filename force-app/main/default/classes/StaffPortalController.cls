public without sharing class StaffPortalController {

    @AuraEnabled(cacheable=true)
    public static List<Cruise__c> getDailyCruises(Date selectedDate) {
        if (selectedDate == null) {
            selectedDate = Date.today();
        }
        DateTime dayStart = DateTime.newInstance(selectedDate, Time.newInstance(0, 0, 0, 0));
        DateTime dayEnd = DateTime.newInstance(selectedDate.addDays(1), Time.newInstance(0, 0, 0, 0));
        
        return [SELECT Id, Name, Boat__c, Boat__r.Name, Boat__r.BoatsSchedulerOrder__c, Start_Date__c, End_Date__c, 
                       Status__c, RecordType.Name, RecordType.DeveloperName, Guide__r.Name, Employee_Phone__c, 
                       Employee_Email__c, CUSTOMER_NAME__c, CUSTOMER_PHONE__c, Additional_Info__c, AccountName__r.Name, 
                       Skipper__r.Name, Course_Type__c, type_of_enriching__c, information__c 
                FROM Cruise__c 
                WHERE Start_Date__c >= :dayStart AND Start_Date__c < :dayEnd AND Status__c != 'Canceled' 
                ORDER BY Boat__r.BoatsSchedulerOrder__c, Start_Date__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<Cruise__c> getGuideCruises(Id employeeId) {
        if (employeeId == null) {
            return new List<Cruise__c>();
        }
        Date today = Date.today();
        DateTime startOfToday = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0));
        return [SELECT Id, Name, Start_Date__c, End_Date__c, Boat__r.Name, RecordType.Name, RecordType.DeveloperName, Additional_Info__c, 
                       Status__c, day__c, cruise_time_formula__c, CUSTOMER_NAME__c, CUSTOMER_PHONE__c, information__c 
                FROM Cruise__c 
                WHERE Guide__c = :employeeId AND Guide__c != null AND Status__c != 'Canceled' AND Start_Date__c >= :startOfToday 
                ORDER BY Start_Date__c ASC];
    }

    @AuraEnabled(cacheable=true)
    public static List<Co_Cruise_Members__c> getCruiseParticipants(Id cruiseId) {
        if (cruiseId == null) {
            return new List<Co_Cruise_Members__c>();
        }
        return [SELECT Id, Account_Co__r.Name, Phone__c, Status__c, SailType__c 
                FROM Co_Cruise_Members__c 
                WHERE Cruise__c = :cruiseId AND Status__c != 'Canceled' 
                ORDER BY Account_Co__r.Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<Boats__c> getActiveBoats() {
        return [SELECT Id, Name, Type__c, BoatsSchedulerOrder__c 
                FROM Boats__c 
                WHERE Active__c = true 
                ORDER BY BoatsSchedulerOrder__c];
    }

    @AuraEnabled(cacheable=true)
    public static Employee__c getEmployeeDetails(Id employeeId) {
        if (employeeId == null) return null;
        List<Employee__c> emps = [SELECT Id, Name, Employee_Type__c, Active__c FROM Employee__c WHERE Id = :employeeId LIMIT 1];
        return emps.isEmpty() ? null : emps[0];
    }
}
