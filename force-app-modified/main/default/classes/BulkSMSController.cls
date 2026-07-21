/**
 * Created by Nabhan on 12/31/2020.
 */

public with sharing class BulkSMSController {
    final static String FROM_ADDRESS = 'yonatan@sea-time.co.il';
    final static String TO_ADDRESS = 'bodygw@sms.inforu.co.il';

    @AuraEnabled
    public static Boolean sendSMSToCourseMembers(String courseId) {
        List<Partecipant__c> partecipants = [
                SELECT Id, Partecipant__r.Phone, course__r.SMS_Message__c
                FROM Partecipant__c
                WHERE course__c = :courseId
        ];

        List<OrgWideEmailAddress> owes = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = :FROM_ADDRESS
        ];

        try {
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

            for (Partecipant__c objPartecipant : partecipants) {
                Messaging.SingleEmailMessage objSingleEmailMessage = new Messaging.SingleEmailMessage();
                objSingleEmailMessage.setOrgWideEmailAddressId(owes[0].Id);
                objSingleEmailMessage.setSubject(objPartecipant.Partecipant__r.Phone);
                objSingleEmailMessage.setPlainTextBody(objPartecipant.course__r.SMS_Message__c);
                objSingleEmailMessage.setToAddresses(new String[] {TO_ADDRESS});
                emailMessages.add(objSingleEmailMessage);
            }
            Messaging.sendEmail(emailMessages);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            return false;
        }
        return true;
    }

    @AuraEnabled
    public static Boolean sendSMSToCruiseMembers(String cruiseId) {
        List<Co_Cruise_Members__c> cruiseMembers = [
                SELECT Id, Cruise__r.SMS_Message__c, Account_Co__r.Phone
                FROM Co_Cruise_Members__c
                WHERE Cruise__c = :cruiseId
        ];

        List<OrgWideEmailAddress> owes = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = :FROM_ADDRESS
        ];

        try {
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

            for (Co_Cruise_Members__c objCruiseMember : cruiseMembers) {
                Messaging.SingleEmailMessage objSingleEmailMessage = new Messaging.SingleEmailMessage();
                objSingleEmailMessage.setOrgWideEmailAddressId(owes[0].Id);
                objSingleEmailMessage.setSubject(objCruiseMember.Account_Co__r.Phone);
                objSingleEmailMessage.setPlainTextBody(objCruiseMember.Cruise__r.SMS_Message__c);
                objSingleEmailMessage.setToAddresses(new String[] {TO_ADDRESS});
                emailMessages.add(objSingleEmailMessage);
            }
            Messaging.sendEmail(emailMessages);
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            return false;
        }
        return true;
    }
}