/*
*  Author        :   Sameer Pandey
*  Created on    :   14th Sep 2021
*  Description   :   Trigger handler class to automatically generating the pulink link url of uploaded document
*                    we can then use that link to view and download the document on comunity and public site.
*/

public class ContentTriggerHandler {
    public static void createPublicLinkForFile(List<ContentVersion> contentVersions){
        ContentDistribution[] distributionsToInsert = new List<ContentDistribution>();
        for(ContentVersion objContentVersion : contentVersions){
            distributionsToInsert.add(createContentDistribution(objContentVersion.Id));
        }
        if(!distributionsToInsert.isEmpty())
        {
            insert distributionsToInsert;
        }
    }
    
    public static ContentDistribution createContentDistribution(Id contentVersionId){
        ContentDistribution newDist = new ContentDistribution();
        newDist.ContentVersionId = contentVersionId;
        newDist.Name = 'External Link';
        newDist.PreferencesNotifyOnVisit = false;
        newDist.PreferencesAllowViewInBrowser = true;
        newDist.PreferencesAllowOriginalDownload=true;
        system.debug('createContentDistribution creted');
        return newDist;
    }
}