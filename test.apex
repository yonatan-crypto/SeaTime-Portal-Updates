Boats__c b = [SELECT Id, (SELECT Id FROM Boat__r WHERE Start_Date__c < 2026-04-17T00:00:00Z AND End_Date__c > 2026-04-16T00:00:00Z AND Status__c != 'Canceled') FROM Boats__c WHERE Name LIKE '%טוויקס%' LIMIT 1];
System.debug('Twix Cruises (Subquery): ' + b.Boat__r.size());
if (b.Boat__r.size() > 0) {
    System.debug('Cruise ID: ' + b.Boat__r[0].Id);
}
