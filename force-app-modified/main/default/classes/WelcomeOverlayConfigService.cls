// created apex for CMDT value 1738
public without sharing class WelcomeOverlayConfigService {
    public static Welcome_Overlay_Config__mdt getConfig() {
        return [
            SELECT Overlay_URL__c,
                   Overlay_BG__c,
                   Block_Page__c
            FROM Welcome_Overlay_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];
    }
}