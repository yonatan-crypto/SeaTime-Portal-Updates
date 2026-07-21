/*
 *  Author        :   Sameer Pandey
 *  Created on    :   14th Sep 2021
 *  Description   :   Trigger to automatically generating the pulink link url of uploaded document
 *                    we can then use that link to view and download the document on comunity and public site.
 */


trigger contentVersionExternalLink on ContentVersion (after insert) {
     ContentTriggerHandler.createPublicLinkForFile(trigger.new);
}