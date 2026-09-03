public without sharing class StaffActiveStatusBatch implements Database.Batchable<sObject>, Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new StaffActiveStatusBatch(), 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Name, Active__c FROM Employee__c]);
    }

    public void execute(Database.BatchableContext bc, List<Employee__c> scope) {
        updateActiveStatus(scope);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('StaffActiveStatusBatch completed.');
    }

    /**
     * Checks if each employee has had any non-canceled cruise in the last 6 months (180 days).
     * If yes, Active__c = true. If no, Active__c = false.
     */
    public static void updateActiveStatus(List<Employee__c> employees) {
        if (employees == null || employees.isEmpty()) return;

        DateTime sixMonthsAgo = DateTime.now().addDays(-180);
        Set<Id> empIds = new Map<Id, Employee__c>(employees).keySet();

        Set<Id> activeGuideIds = new Set<Id>();
        for (AggregateResult ar : [
            SELECT Guide__c
            FROM Cruise__c
            WHERE Guide__c IN :empIds
              AND Status__c != 'Canceled'
              AND Start_Date__c >= :sixMonthsAgo
            GROUP BY Guide__c
        ]) {
            activeGuideIds.add((Id)ar.get('Guide__c'));
        }

        List<Employee__c> toUpdate = new List<Employee__c>();
        for (Employee__c emp : employees) {
            Boolean shouldBeActive = activeGuideIds.contains(emp.Id);
            if (emp.Active__c != shouldBeActive) {
                emp.Active__c = shouldBeActive;
                toUpdate.add(emp);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
            System.debug('Updated ' + toUpdate.size() + ' employees active status.');
        }
    }

    /**
     * Helper to run immediate update for all employees in org.
     */
    public static void runNow() {
        List<Employee__c> allEmps = [SELECT Id, Name, Active__c FROM Employee__c];
        updateActiveStatus(allEmps);
    }

    /**
     * Helper to schedule automatic daily check at 02:00 AM.
     */
    public static void scheduleDaily() {
        String jobName = 'Daily Staff Active Status Check';
        List<CronTrigger> existing = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
        for (CronTrigger ct : existing) {
            System.abortJob(ct.Id);
        }
        System.schedule(jobName, '0 0 2 * * ?', new StaffActiveStatusBatch());
    }
}
