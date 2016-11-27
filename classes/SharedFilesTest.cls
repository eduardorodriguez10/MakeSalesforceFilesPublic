@isTest
public class SharedFilesTest {
    
    @isTest
    private static void should_create_shared_file_record()
    {
        List<Account> vendor = DataFactory.createVendors(1); 
        List<Contact> theContact = DataFactory.createContacts(1, vendor[0].Id);
        Map<Id,Contact> contacsMap = new Map<Id,Contact>(theContact);
        Test.startTest();
            DataFactory.createFiles(1, contacsMap.keySet());
        Test.stopTest();
        List<Shared_File__c> sharedFiles = [SELECT Id FROM Shared_File__c WHERE RelatedRecordId__c =: theContact[0].Id];
        System.assertNotEquals(null, sharedFiles);
        System.assertNotEquals(0, sharedFiles.size());
    }
    
    @isTest
    private static void should_delete_shared_file_record_if_content_deleted()
    {
        List<Account> vendor = DataFactory.createVendors(1); 
        List<Contact> theContact = DataFactory.createContacts(1, vendor[0].Id);
        Map<Id,Contact> contacsMap = new Map<Id,Contact>(theContact);
        DataFactory.createFiles(1, contacsMap.keySet());
        Test.startTest();
            List<ContentDocument> existingContent = [SELECT Id FROM ContentDocument];
            delete existingContent;
        Test.stopTest();
        List<Shared_File__c> sharedFiles = [SELECT Id FROM Shared_File__c WHERE RelatedRecordId__c =: theContact[0].Id];
        System.assertNotEquals(null, sharedFiles);
        System.assertEquals(0, sharedFiles.size());
    }
}