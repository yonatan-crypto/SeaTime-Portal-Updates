@isTest
public with sharing class SchemaUtilityServiceTest {
     public static testMethod void getLabelOfFieldTest(){
       SchemaUtilityService schList = new SchemaUtilityService();
       String [] labelArr = new List<String>{'רציף','מרינה','הרצליה', 'תל אביב','חיפה'};
       integer i=0;
     	map <String, String> MapTest =  SchemaUtilityService.getFieldLabelMap('Boats__c','Convertion__c');
		system.assertEquals(MapTest.get('Convertion__c'),'יחס המרה');
		test.startTest();
        	map <String, String> MapTestPickList =  SchemaUtilityService.getFieldLabelMap('Boats__c','Docking__c');
        test.stopTest();
        for (String apiItem: MapTestPickList.keyset()){
            system.debug('MapTestPickList.get(apiItem)= '+ MapTestPickList.get(apiItem));
            system.assertEquals(MapTestPickList.get(apiItem),labelArr[i]);
            i++;
        }
     }
     
}