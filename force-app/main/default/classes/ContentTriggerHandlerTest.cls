@isTest
public class ContentTriggerHandlerTest {
    @isTest
    public static void createPublicLinkForFileTest(){
        ContentVersion cVersion = new Contentversion();
        cVersion.title='test';
        cVersion.PathOnClient ='test ABC';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cVersion.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert cVersion;
    }
}