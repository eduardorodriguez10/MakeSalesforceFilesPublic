@isTest
public class SharedFilesTest {
    
    @isTest
    private static void should_create_shared_file_record()
    {
        List<Account> vendor = DataFactory.createAccounts(1); 
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
        List<Account> vendor = DataFactory.createAccounts(1); 
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
    
    @isTest
    private static void should_remove_distribution_if_unshared()
    {
        List<Account> vendor = DataFactory.createAccounts(1); 
        List<Contact> theContact = DataFactory.createContacts(1, vendor[0].Id);
        Map<Id,Contact> contacsMap = new Map<Id,Contact>(theContact);
        DataFactory.createFiles(1, contacsMap.keySet());
        List<Shared_File__c> theSharedFiles = [SELECT Id, ContentDocumentId__c FROM Shared_File__c WHERE RelatedRecordId__c =: theContact[0].Id];
        System.assertNotEquals(null, theSharedFiles);
        System.assertNotEquals(0, theSharedFiles.size());
        Set<Id> documentIds = new Set<Id>(); 
        for(Shared_File__c sf: theSharedFiles) documentIds.add(sf.ContentDocumentId__c);
        SharedFileService.unshareSharedFiles(documentIds);
        List<Shared_File__c> theUpdatedSharedFiles = [SELECT Id, ContentDocumentId__c, Download_Link__c FROM Shared_File__c WHERE RelatedRecordId__c =: theContact[0].Id];
        for(Shared_File__c sf: theUpdatedSharedFiles) System.assertEquals(null, sf.Download_Link__c); 
        List<ContentDistribution> theDistributions = [SELECT Id FROM ContentDistribution]; 
        System.assertEquals(0, theDistributions.size());
    }
    
    @isTest
    private static void should_reshare_distribution_if_reshared()
    {
        List<Account> vendor = DataFactory.createAccounts(1); 
        List<Contact> theContact = DataFactory.createContacts(1, vendor[0].Id);
        Map<Id,Contact> contacsMap = new Map<Id,Contact>(theContact);
        DataFactory.createFiles(1, contacsMap.keySet());
        List<Shared_File__c> theSharedFiles = [SELECT Id, ContentDocumentId__c FROM Shared_File__c WHERE RelatedRecordId__c =: theContact[0].Id];
        System.assertNotEquals(null, theSharedFiles);
        System.assertNotEquals(0, theSharedFiles.size());
        Set<Id> documentIds = new Set<Id>(); 
        for(Shared_File__c sf: theSharedFiles) documentIds.add(sf.ContentDocumentId__c);
        SharedFileService.unshareSharedFiles(documentIds);
        List<Shared_File__c> theUpdatedSharedFiles = [SELECT Id, ContentDocumentId__c, Download_Link__c FROM Shared_File__c WHERE RelatedRecordId__c =: theContact[0].Id];
        for(Shared_File__c sf: theUpdatedSharedFiles) System.assertEquals(null, sf.Download_Link__c); 
        List<ContentDistribution> theDistributions = [SELECT Id FROM ContentDistribution]; 
        System.assertEquals(0, theDistributions.size());
        SharedFileService.reshareSharedFiles(documentIds);
        List<Shared_File__c> theResharedSharedFiles = [SELECT Id, ContentDocumentId__c, Download_Link__c FROM Shared_File__c WHERE RelatedRecordId__c =: theContact[0].Id];
        for(Shared_File__c sf: theResharedSharedFiles) System.assertNotEquals(null, sf.Download_Link__c); 
        List<ContentDistribution> theNewDistributions = [SELECT Id FROM ContentDistribution]; 
        System.assertNotEquals(0, theNewDistributions.size());
    }
    
    @isTest
    private static void should_update_descriptions()
    {
        List<Account> vendor = DataFactory.createAccounts(1); 
        List<Contact> theContact = DataFactory.createContacts(1, vendor[0].Id);
        Map<Id,Contact> contacsMap = new Map<Id,Contact>(theContact);
        DataFactory.createFiles(1, contacsMap.keySet());
        List<Shared_File__c> theSharedFiles = [SELECT Id, ContentDocumentId__c FROM Shared_File__c WHERE RelatedRecordId__c =: theContact[0].Id];
        System.assertNotEquals(null, theSharedFiles);
        System.assertNotEquals(0, theSharedFiles.size());
        Set<Id> documentIds = new Set<Id>(); 
        Map<Id,String> mapIdToDescription = new Map<Id,String>();
        for(Shared_File__c sf: theSharedFiles)
        {
            documentIds.add(sf.ContentDocumentId__c);
            mapIdToDescription.put(sf.ContentDocumentId__c, 'Test description');
        }
        SharedFileService.updateLatestVersionsDescriptions(mapIdToDescription);
        List<ContentVersion> updatedVersions = [SELECT Id, Description, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN: documentIds AND isLatest = true]; 
        for(ContentVersion cv: updatedVersions)
        {
            System.assertEquals(cv.Description, 'Test description');
        }
    }
}