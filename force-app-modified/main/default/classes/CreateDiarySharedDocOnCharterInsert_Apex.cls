/*
*  Author        :   Sameer Pandey
*  Created on    :   14th Sep 2021
*  Description   :   Trigger handler class to automatically generating the pulink link url of uploaded document
*                    we can then use that link to view and download the document on comunity and public site.
*/

public class CreateDiarySharedDocOnCharterInsert_Apex {
    public static void insertChildRecord(List<charters__c> charterList){
        List<Diary__c> diaryList = new List<Diary__c>();
        List<Shared_Documents__c> sharedDocList = new List<Shared_Documents__c>();
        for(charters__c charter :charterList){
            Diary__c diary = new Diary__c();
            diary.CharterId__c = charter.Id ;
            diaryList.add(diary);
            
            Shared_Documents__c sharedDoc = new Shared_Documents__c();
            sharedDoc.Charter__c = charter.Id ;
            sharedDoc.Name = 'Shared '+ charter.Name ;
            sharedDocList.add(sharedDoc);
        }
        insert diaryList ;
        insert sharedDocList ;
    }
}