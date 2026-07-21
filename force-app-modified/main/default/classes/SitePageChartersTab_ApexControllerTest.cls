@isTest
public class SitePageChartersTab_ApexControllerTest {
    
    @isTest
    public static void stePageChartersTabApexControllertestAllMethods(){
        Test.startTest();
        try{
            Account acc = new Account(Name = 'test account');
            insert acc;
            
            Charters__c chart = new Charters__c();
            chart.client__c = acc.id;
            chart.yacht_type__c = 'מונו';
            chart.yacht_model__c = 'Benetaeu'; 
            chart.cabins__c = 3;
            chart.WC__c = 2;
            chart.charter_booking_date__c = date.today();
            insert chart;
       
            List<charters__c> chartersList = SitePageChartersTab_ApexController.getAllChartersRecords(acc.id);
            System.assertEquals(acc.id,chartersList[0].client__c);
            
            Diary__c dary = new Diary__c();
            dary.CharterId__c = chart.id;
            //insert dary;
             
            Map<charters__c,List<ContentDocument>> charterIdVSListOfContentDocumentObj = SitePageChartersTab_ApexController.getAllChartersVsDocumentRecords(acc.id);
            List<charters__c> chatList = new List<charters__c>();
			chatList.addAll(charterIdVSListOfContentDocumentObj.keySet());                                                                                                                                                                                                                                                                                                                                                                                                                             
            System.assertEquals(chart.id ,chatList[0].id);
            
            
            ContentVersion cv = new ContentVersion();
            cv.Title = 'test';
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test document');
            cv.IsMajorVersion = true;
            Insert cv;
            
            //Get Content Documents
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            
            Shared_Documents__c sharDoc = new Shared_Documents__c();
            sharDoc.Charter__c = chart.id;
            insert sharDoc;
            
            //Create ContentDocumentLink 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = sharDoc.Id;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            Insert cdl;
              
            List<ContentDocument> contList =  SitePageChartersTab_ApexController.getAllContentDocumentsSharedDocument(chart.id);
            System.assertEquals(conDocId, contList[0].id);
           
            
            Id sitePageChartersTabId = SitePageChartersTab_ApexController.saveChunk(chart.id, 'test', 'This is version data', 'pdf', '');
        	System.assert(sitePageChartersTabId != null);
           
            Id sitePageChar = SitePageChartersTab_ApexController.saveChunkCharter(chart.id, 'test', 'This is version data', 'pdf', '', 'press1');
            System.assert(sitePageChar != null);
            
            String conDiscription =  SitePageChartersTab_ApexController.getPublicLinkURLForSelectedFile(conDocId);
            ContentDistribution conDist = [Select id, DistributionPublicUrl From ContentDistribution where ContentDocumentId =: conDocId LIMIT 1];
            System.assertEquals(conDist.DistributionPublicUrl,conDiscription);
            
        }
        catch(Exception ex){
            System.debug('Exception '+ex.getMessage());
        }
        Test.stopTest();
    }   
}