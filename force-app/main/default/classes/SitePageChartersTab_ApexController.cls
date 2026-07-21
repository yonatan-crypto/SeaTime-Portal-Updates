/*    Created By       :     Sameer Pandey
*    Created date     :     26th August 2021
*    Description      :     This apex class is the controller class of SitePageChartersTab component.
It handles the required server side actions of the component.
*/



public without sharing class SitePageChartersTab_ApexController {
    
    
    @AuraEnabled
    public static List<charters__c> getAllChartersRecords(String accountId){
        //system.debug('accountId==>'+accountId);
        List<charters__c> chartersList = new List<charters__c>();
        if(!String.isEmpty(accountId)){
            // system.debug('test-->'+String.isEmpty(accountId));
            chartersList = [SELECT Id,Name,Skipper_Licence_Button1__c,Photography_Button2__c,Staff_List_Button3__c,charter_booking_date__c,Area_of_Sail__c,Area_of_Sail__r.Name,client__r.Name,client__r.Id,WC__c,extra1__c,extra2__c,extra3__c,extra4__c,extra1price__c,extra2price__c,extra3price__c,extra4price__c,client_price_after_discount__c,FirstPaymentDate__c,SecondPaymentDate__c,ThirdPaymentDate__c,yacht_length__c,cabins__c,DEPOSIT__c,equipment__c, charter_date__c,marina__c,charter_company__c,charter_company__r.Name,YachtYear__c,yacht_model__c,CharterClientEmail__c FROM Charters__c WHERE client__c =: accountId and charter_booking_date__c != null  order by charter_date__c desc Limit 1000];
        }
        
        // system.debug('chartersList-->'+chartersList);
        return chartersList;
        
    }

    
    @AuraEnabled
    public static Map<charters__c,List<ContentDocument>> getAllChartersVsDocumentRecords(String accountId){
        System.debug('account Id -->'+accountId);
        List<Diary__c> diaryList = new List<Diary__c>();
        List<ContentDocument> conDocsList = new List<ContentDocument>();
        Set<Id> ContentDocsId=new Set<Id>();
        List<id> diaryIdList = new List<id>();
        if(!String.isEmpty(accountId)){
            diaryList = [Select id,Name,CharterId__c,CharterId__r.name from Diary__c where CharterId__r.client__c =: accountId];
            System.debug('at 35 -->'+diaryList);
            for(Diary__c diaryObj:diaryList){
                diaryIdList.add(diaryObj.id);
            }
            System.debug('Diary List at 39 -->'+diaryIdList);
            
            
        }
        Map<String,List<ContentDocument>> diaryIdVsListOfContendDocumentObj = new Map<String,List<ContentDocument>>();        
        /*if(!diaryList.isEmpty()){
            For(ContentDocumentLink conDocLink : [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId In : diaryList LIMIT 1000]){
                ContentDocsId.add(conDocLink.ContentDocumentId);
                if(diaryIdVsListOfContendDocumentObj.containsKey(conDocLink.LinkedEntityId)){                    
                    diaryIdVsListOfContendDocumentObj.get(conDocLink.LinkedEntityId).add(conDocLink.ContentDocumentId); 
                }else{
                    List<String> ContentDocumentIdList = new List<String>();
                    ContentDocumentIdList.add(conDocLink.ContentDocumentId);
                    diaryIdVsListOfContendDocumentObj.put(conDocLink.LinkedEntityId,ContentDocumentIdList);
                }
            }
        }*/
        Set<id> condocId = new Set<id>();        
        List<ContentDocumentLink> ContentDocumentLinkList = [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in : diaryIdList];
        map<string,string> contentDocumentIdVsDiaryId = new map<string,string>();
        System.debug('contentDocumentList at 57 -->'+ContentDocumentLinkList);
        for(ContentDocumentLink conDocLink:ContentDocumentLinkList){
            contentDocumentIdVsDiaryId.put(conDocLink.ContentDocumentId,conDocLink.LinkedEntityId);
            condocId.add(conDocLink.ContentDocumentId);
        }
        list<ContentDocument> contentDocumentList = [SELECT Id,Title,FileType,CreatedBy.Name,ContentSize From contentDocument WHERE id in :condocId];
        
        For(ContentDocument conDoc : contentDocumentList){
                //ContentDocsId.add(conDocLink.ContentDocumentId);
                if(diaryIdVsListOfContendDocumentObj.containsKey(contentDocumentIdVsDiaryId.get(conDoc.id))){                    
                    diaryIdVsListOfContendDocumentObj.get(contentDocumentIdVsDiaryId.get(conDoc.id)).add(conDoc); 
                }else{
                    List<ContentDocument> ContentDocumentIdList = new List<ContentDocument>();
                    ContentDocumentIdList.add(conDoc);
                    diaryIdVsListOfContendDocumentObj.put(contentDocumentIdVsDiaryId.get(conDoc.id),ContentDocumentIdList);
                }
        }
        System.debug('diaryIdVsListOfContendDocumentObj Map at 66 --'+diaryIdVsListOfContendDocumentObj);
        Map<charters__c,List<ContentDocument>> charterIdVSListOfContentDocumentObj = new Map<charters__c,List<ContentDocument>>();
        for(Diary__c diary:diaryList){
            charters__c charterObj = new charters__c(id= diary.CharterId__c);
            if(charterIdVSListOfContentDocumentObj.containsKey(charterObj)){
                charterIdVSListOfContentDocumentObj.get(charterObj).addAll(diaryIdVsListOfContendDocumentObj.get(diary.id));
            }else{
                List<ContentDocument> ContentDocumentIdList = diaryIdVsListOfContendDocumentObj.get(diary.id);
                charterIdVSListOfContentDocumentObj.put(charterObj,ContentDocumentIdList);
            }
        }
        System.debug('charterIdVSListOfContentDocumentObj at 77 '+charterIdVSListOfContentDocumentObj);
        return charterIdVSListOfContentDocumentObj;
        
    }
    
    /*
    @AuraEnabled
    public static List<ContentDocument> getAllContentDocuments(String parentId){
        try{
            Set<Id> ContentDocsId=new Set<Id>();
            For(ContentDocumentLink conDocLink : [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :parentId LIMIT 1000]){
                ContentDocsId.add(conDocLink.ContentDocumentId);
            }
            List<ContentDocument> conDocsList = new List<ContentDocument>();
            for(ContentDocument conDoc : [SELECT Id,Title,FileType,CreatedBy.Name,ContentSize From contentDocument WHERE Id IN : ContentDocsId]){
                conDocsList.add(conDoc);
            }
            if(!conDocsList.isEmpty()){
                return conDocsList;
            }
            
            else {return null;}
        }
        catch(Exception exec){
            System.debug('Exception occurred while showing the record detail. \n Message :' + exec.getMessage() + ' Line number :' + exec.getLineNumber()
                         + ' Cause :' + exec.getCause());
            throw new AuraHandledException('  Unable to show record detail-'+ 'Message :'+ exec.getMessage());
        }
        
    }*/
    
    @AuraEnabled
    public static List<ContentDocument> getAllContentDocumentsSharedDocument(String charterId){
        try{
            List<ContentDocument> conDocsList = new List<ContentDocument>();
            List<Charters__c> chartersList = new List<Charters__c>();
            chartersList = [SELECT Id,Name,Area_of_Sail__c FROM Charters__c WHERE id =: charterId and Area_of_Sail__c != null Limit 1 ];
            System.debug('chartersList  at 123 -->'+chartersList);
            List<Shared_Documents__c> sharedList = new List<Shared_Documents__c>();
            sharedList = [select id,Name,Charter__c from Shared_Documents__c where Charter__c =: charterId Limit 1000] ;
            System.debug('sharedList  at 126 ->'+sharedList);
            Set<id> shareDocId = new Set<id>();
            if(!sharedList.isEmpty()){
                for(Shared_Documents__c shareDoc : sharedList){
                    shareDocId.add(shareDoc.Id);
                }
            }
            
            
            Set<Id> ContentDocsId=new Set<Id>();  
            if(!chartersList.isEmpty()){
                For(ContentDocumentLink conDocLink : [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :chartersList[0].Area_of_Sail__c LIMIT 1000]){
                    ContentDocsId.add(conDocLink.ContentDocumentId);
                }
                System.debug('ContentDocsId at 140 -->'+ContentDocsId);
                System.debug('size at 67 -->'+ContentDocsId.size());
            }
            if(!shareDocId.isEmpty()){
                For(ContentDocumentLink conDocLink : [SELECT Id,ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN : shareDocId LIMIT 1000]){
                    ContentDocsId.add(conDocLink.ContentDocumentId);
                }
            }
            System.debug('ContentDocsId at 146 -->'+ContentDocsId);
            System.debug('size at 147 -->'+ContentDocsId.size()); 
            if(!ContentDocsId.isEmpty()){
                for(ContentDocument conDoc : [SELECT Id,Title,FileType,CreatedBy.Name,ContentSize From contentDocument WHERE Id IN : ContentDocsId]){
                    conDocsList.add(conDoc);
                }
            }
            System.debug('conDocsList size at 152'+conDocsList.size());
            
            if(!conDocsList.isEmpty()){
                return conDocsList;
            }
            
            else {return null;}
        }
        catch(Exception exec){
            System.debug('Exception occurred while showing the record detail. \n Message :' + exec.getMessage() + ' Line number :' + exec.getLineNumber()
                         + ' Cause :' + exec.getCause());
            throw new AuraHandledException('  Unable to show record detail-'+ 'Message :'+ exec.getMessage());
        }
        
    }
    
    
    @AuraEnabled
    public static Id saveChunk(Id parentId, String fileName, String base64Data, String contentType, String fileId) {
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert, 
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with reamins chunks   
        system.debug('parentId '+parentId+' fileName '+fileName+' base64Data '+base64Data);
        List<Diary__c> diaryList = new List<Diary__c>();
        diaryList = [select id,name,CharterId__c from Diary__c where CharterId__c =: parentId limit 1];
        if(diaryList.isEmpty()){
            Diary__c diary = new Diary__c();
            diary.CharterId__c = parentId ;
            diaryList.add(diary);
            insert diaryList ;
            
        }
        if (fileId == '') {
            fileId = saveTheFile(diaryList[0].id, fileName, base64Data, contentType);
        }
        
        return Id.valueOf(fileId);
    }
    
     @AuraEnabled
    public static Id saveChunkCharter(Id parentId, String fileName, String base64Data, String contentType, String fileId, String fileId1) {
        // check if fileId id ''(Always blank in first chunk), then call the saveTheFile method,
        //  which is save the check data and return the attachemnt Id after insert, 
        //  next time (in else) we are call the appentTOFile() method
        //   for update the attachment with reamins chunks   
        system.debug('parentId '+parentId+' fileName '+fileName+' base64Data '+base64Data);
        System.debug('fileId1 at 193 line -->'+fileId1);
        List<charters__c> charterList = new List<charters__c>();
        charterList = [select id,name,client__c,Skipper_Licence_Button1__c,Photography_Button2__c,Staff_List_Button3__c from charters__c where id =: parentId limit 1];
        System.debug('charterList at 194-->'+charterList);
        if (fileId == '') {
            fileId = saveTheFile(charterList[0].id, fileName, base64Data, contentType);
            System.debug('fileName-->'+fileName);
        }
        
        if(fileId1 == 'press1'){
            charterList[0].Skipper_Licence_Button1__c = true ;
        }else if(fileId1 == 'press2'){
            charterList[0].Photography_Button2__c = true ;
        }else if(fileId1 == 'press3'){
            charterList[0].Staff_List_Button3__c = true ;
        }
        
        if(!charterList.isEmpty()){
            update charterList ;
        }
        
        return Id.valueOf(fileId);
    }
    
    
    public static Id saveTheFile(Id parentId, String fileName, String base64Data, String contentType) {
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
        ContentVersion contentToInsert =new ContentVersion(); 
        contentToInsert.Title =fileName; 
        contentToInsert.VersionData=EncodingUtil.base64Decode(base64Data);
        contentToInsert.PathOnClient='/' + fileName ;
        contentToInsert.IsMajorVersion = false;
        database.insert(contentToInsert); 
        system.debug('contentToInsert-->'+contentToInsert);
        system.debug('contentId-->'+contentToInsert.Id);
        
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId 
                                           FROM ContentVersion WHERE Id = :contentToInsert.Id LIMIT 1];
        system.debug('contentDocumentId-->'+contentVersion_2.ContentDocumentId);
        
        //contentToInsert = [select id, ContentDocumentId from ContentVersion WHERE Id =: contentToInsert.Id];
        system.debug('contentToInsert-->'+contentVersion_2.ContentDocumentId);
        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = contentVersion_2.ContentDocumentId;
        cl.LinkedEntityId = parentId; 
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;
        
        return contentToInsert.id;
    }
    
    
    @AuraEnabled
    public static string getPublicLinkURLForSelectedFile (String contentDocumentId){
        List<ContentDistribution> cdrList = new List<ContentDistribution>();
        if(!String.isBlank(contentDocumentId)){
            cdrList = [Select ContentDownloadUrl,DistributionPublicUrl From ContentDistribution where ContentDocumentId =: contentDocumentId];
        }
        
        return cdrList[0].DistributionPublicUrl; 
        
    }
    
    
}