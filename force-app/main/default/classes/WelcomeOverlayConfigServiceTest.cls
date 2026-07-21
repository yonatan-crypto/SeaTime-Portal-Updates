@IsTest
public class WelcomeOverlayConfigServiceTest {

    @IsTest
    static void testGetConfig() {
        Test.startTest();
        
        // Call the CMDT service
        Welcome_Overlay_Config__mdt config = WelcomeOverlayConfigService.getConfig();
        
        // Assertions
        System.assertNotEquals(null, config, 'CMDT record should not be null');
        System.assertNotEquals('', config.Overlay_URL__c, 'Overlay URL should not be empty');
        System.assertNotEquals('', config.Overlay_BG__c, 'Overlay BG should not be empty');
        
        Test.stopTest();
    }
}