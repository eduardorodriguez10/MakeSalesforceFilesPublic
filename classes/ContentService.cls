public class ContentService {
    
    // Returns a map of the ContentDocumentId to the LatestVersionId
    public static Map<Id,Id> getMapOfContentDocumentToLatestVersion(List<ContentVersion> docVersions)
    {
        // get the document Ids of the latest versions upserted
        // to identify if they are related to a service contract record
        Map<Id,Id> documentToVersionIdsOfLatestVersionsMap = new Map<Id,Id>();

        for(ContentVersion cv: docVersions)
        {
            // Get the new document versions if they are the latest
            if(cv.isLatest) documentToVersionIdsOfLatestVersionsMap.put(cv.ContentDocumentId, cv.Id);
        }
        
        return documentToVersionIdsOfLatestVersionsMap;
    }
    
    // Returns a Set of SObjectNames in the LinkedEntity of the ContentDocumentLink for all Content Documents in Set
    public static Set<String> getDocumentsSObjectNames(Set<Id> documentIds) 
    {
        Set<String> sObjectNames = new Set<String>(); 
        // query content documents to check if related to service contract
        List<ContentDocumentLink> allContentDocumentsLinks = [SELECT ContentDocument.title, ContentDocument.FileType, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: documentIds];
        
        if(allContentDocumentsLinks == null || allContentDocumentsLinks.isEmpty()) return sObjectNames; 
        
        for(ContentDocumentLink cdl: allContentDocumentsLinks)
        {
            // check if content is related to a SSP_Services_Contract__c record
            if(cdl.LinkedEntityId != null)
            {
                // Do not return the User SObjectName, we are not sharing documents per user
                if(cdl.LinkedEntityId.getSObjectType() != User.SObjectType)
                    sObjectNames.add(cdl.LinkedEntityId.getSObjectType().getDescribe().getName());
            }
        }
        
        return sObjectNames;
    }
    
    // It returns a map including al list of ContentVersions for each SObjectName
    public static Map<String,List<ContentVersion>> getSObjectNameToVersionsMap(List<ContentVersion> theVersions, Set<String> sObjectNames)
    {
        Map<String,List<ContentVersion>> sObjectNameToVersionsMap = new Map<String,List<ContentVersion>>(); 
        Map<Id,ContentVersion> mapIdToContentVersion = new Map<Id,ContentVersion>(theVersions);
        Map<Id,Id> docIdToVersionMap = ContentService.getMapOfContentDocumentToLatestVersion(theVersions); 
        Set<Id> theDocumentIds = docIdToVersionMap.keySet(); 
        
        List<ContentDocumentLink> allContentDocumentsLinks = [SELECT ContentDocument.title, ContentDocument.FileType, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: theDocumentIds];
        
        for(String sObjectName: sObjectNames)
        {
            for(ContentDocumentLink cdl: allContentDocumentsLinks)
            {
                // check if content is related to a SSP_Services_Contract__c record
                if(cdl.LinkedEntityId != null && cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == sObjectName)
                {
                    List<ContentVersion> loadedVersions = sObjectNameToVersionsMap.get(sObjectName); 
                    if(loadedVersions == null) loadedVersions = new List<ContentVersion>(); 
                    loadedVersions.add(mapIdToContentVersion.get(docIdToVersionMap.get(cdl.ContentDocumentId)));
                    sObjectNameToVersionsMap.put(sObjectName, loadedVersions);
                }
            }
        }
        return sObjectNameToVersionsMap;
    }
    
    /* Not Used Anymore -- Left for Reference
       Returns a map of all DocumentIds related to a record of the matching sobjecttype
    public static Map<Id,ContentDocumentLink> getDocIdToContentDocumentLinksMapRelatedToSObjectType(Set<Id> documentIds, SObjectType theObjectType)
    {

        // query content documents to check if related to service contract
        List<ContentDocumentLink> allContentDocumentsLinks = [SELECT ContentDocument.title, ContentDocument.FileType, ContentDocument.description, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: documentIds];
        
        Map<Id,ContentDocumentLink> idToContentDocumentMap = new Map<Id,ContentDocumentLink>();
        
        System.debug(':::allContentDocuments = '+allContentDocumentsLinks);
        if(allContentDocumentsLinks != null && !allContentDocumentsLinks.isEmpty())
        {
            for(ContentDocumentLink cdl: allContentDocumentsLinks)
            {
                // check if content is related to a SSP_Services_Contract__c record
                if(cdl.LinkedEntityId != null && cdl.LinkedEntityId.getSObjectType() == theObjectType)
                {
                    // if related added to the set and map for further processing
                    idToContentDocumentMap.put(cdl.ContentDocumentId, cdl);
                }
            }
        }
        
        System.debug(':::documentIdsOfServicesContractsFiles = '+idToContentDocumentMap.keySet());
        return idToContentDocumentMap;
    }*/
    
    // Returns a mapping of Document Ids to Document Links matching the names in the sObjectNames in the LinkedEntityId record
    public static Map<Id,ContentDocumentLink> getDocIdToContentDocumentLinksMap(Set<Id> documentIds, Set<String> sobjectNames)
    {

        // query content documents to check if related to service contract
        List<ContentDocumentLink> allContentDocumentsLinks = [SELECT ContentDocument.title, ContentDocument.FileType, ContentDocument.description,LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: documentIds];
        
        Map<Id,ContentDocumentLink> idToContentDocumentMap = new Map<Id,ContentDocumentLink>();
        
        System.debug(':::allContentDocuments = '+allContentDocumentsLinks);
        if(allContentDocumentsLinks != null && !allContentDocumentsLinks.isEmpty())
        {
            for(ContentDocumentLink cdl: allContentDocumentsLinks)
            {
                // if related added to the set and map for further processing
                if(cdl.LinkedEntityId != null)
                {
                    for(String sObjectName: sObjectNames)
                    {
                        System.debug('::: Checking if '+cdl.LinkedEntityId.getSObjectType()+' == '+Schema.getGlobalDescribe().get(sObjectName));
                        if(cdl.LinkedEntityId.getSObjectType() == Schema.getGlobalDescribe().get(sObjectName))
                            idToContentDocumentMap.put(cdl.ContentDocumentId, cdl);
                    }

                }
            }
        }
        
        System.debug(':::documentIdsOfServicesContractsFiles = '+idToContentDocumentMap.keySet());
        return idToContentDocumentMap;
    }
    
    // Creates a Public Content Distribution for a content document Id if the document doesn't have one
    // Returns the newly created plus any existing ContentDistributions for the contentDocuments
    public static List<ContentDistribution> createOrRetrieveContentDistribution(Set<Id> contentDocumentIds, Map<Id,Id> documentToVersionIdsOfLatestVersionsMap)
    {       
        List<ContentDistribution> sharedLinks = new List<ContentDistribution>(); 
        List<ContentDistribution> sharedLinksToInsert = new List<ContentDistribution>(); 
        
        if(contentDocumentIds == null || contentDocumentIds.isEmpty()) return sharedLinks; 
        if(documentToVersionIdsOfLatestVersionsMap == null || documentToVersionIdsOfLatestVersionsMap.isEmpty()) return sharedLinks; 
        
        Set<Id> documentsWithExistingContentDistributionShares = new Set<Id>(); 
        
        //delete if there are previous shares for this document
        ContentService.deleteContentDistributions(contentDocumentIds); 
        
        // create content distribution and prepare for insert
        for(Id documentId: contentDocumentIds)
        {
            ContentDistribution cd = new ContentDistribution(); 
            cd.ContentVersionId = documentToVersionIdsOfLatestVersionsMap.get(documentId);
            cd.Name = 'share_'+documentId;
            // do not send notification emails when files are viewed
            cd.PreferencesNotifyOnVisit = false; 
            cd.PreferencesNotifyRndtnComplete = false;
            // only insert it if it doesn't have a content distribution yet
            sharedLinksToInsert.add(cd);
        }
        
        if(!sharedLinksToInsert.isEmpty()) insert sharedLinksToInsert; 
        
        sharedLinks = [SELECT Id, ContentDocumentId, ContentVersionId, DistributionPublicUrl FROM ContentDistribution WHERE ContentDocumentId IN: contentDocumentIds];
        
        return sharedLinks;
    }
    
    // Deletes all content distributions for the related content documents
    public static void deleteContentDistributions(Set<Id> contentDocumentIds)
    {       

        if(contentDocumentIds == null || contentDocumentIds.isEmpty()) return; 

        //check if there are previous shares for this document
        List<ContentDistribution> previousCDs = [SELECT Id, ContentDocumentId FROM ContentDistribution WHERE ContentDocumentId IN: contentDocumentIds];
        if(previousCDs != null && !previousCDs.isEmpty())
        {
            // delete previous shares to make sure only the latest version is shared
            delete previousCDs;
        }
    }
    
    // creates Shared_File__c records based on the provided settings
    public static List<Shared_File__c> createShareFileRecords(List<ContentVersion> contentVersions, Map<Id,ContentDocumentLink> idToContentDocumentMap, Shared_Files_Setting__mdt sharedSetting)
    {
        if(contentVersions == null || contentVersions.isEmpty()) return null; 
        if(sharedSetting == null) return null; 
        List<Shared_File__c> sharedFileRecordsToInsert = new List<Shared_File__c>(); 
        List<Shared_File__c> existingFiles = [SELECT Id, Display_In_Public_Site__c, ContentVersionId__c, ContentDocumentId__c, File_Name__c, File_Type__c, RelatedRecordId__c, Description__c FROM Shared_File__c WHERE ContentDocumentId__c IN: idToContentDocumentMap.keySet()];
        Map<Id,Shared_File__c> mapDocIdToSharedFile = new Map<Id,Shared_File__c>();
        for(Shared_File__c existingFile: existingFiles)
        {
            mapDocIdToSharedFile.put(existingFile.ContentDocumentId__c, existingFile);
        }
        
        for(ContentVersion cv: contentVersions)
        {
            Shared_File__c sharedFile = mapDocIdToSharedFile.get(cv.ContentDocumentId);
            if(sharedFile == null) sharedFile = new Shared_File__c(); 
            sharedFile.Display_In_Public_Site__c = sharedSetting.Automatically_Share__c; 
            sharedFile.ContentVersionId__c = cv.Id; 
            sharedfile.ContentDocumentId__c = cv.ContentDocumentId;
            ContentDocumentLink theDocumentLink = idToContentDocumentMap.get(cv.ContentDocumentId);
            sharedfile.File_Name__c = theDocumentLink.ContentDocument.title;
            sharedfile.File_Type__c = theDocumentLink.ContentDocument.fileType;
            sharedFile.RelatedRecordId__c = theDocumentLink.LinkedEntityId; 
            sharedFile.Description__c = theDocumentLink.ContentDocument.description;
            if(sharedFile.Id == null) sharedFileRecordsToInsert.add(sharedFile);
        }
        
        return ContentService.insertSharedFilesWithAccess(sharedFileRecordsToInsert);
    }
    
    // Returns any configured Shared_Files_Settings that match the sObjectName in the ObjectName__c field
    public static Map<String, Shared_Files_Setting__mdt> getSharedFileSettings(Set<String> sObjectNames)
    {
        Map<String,Shared_Files_Setting__mdt> sharedFilesSettingsMap = new Map<String,Shared_Files_Setting__mdt>();
        List<Shared_Files_Setting__mdt> sharedFilesSettings;
        if(!Test.isRunningTest()) sharedFilesSettings = [SELECT Id, ObjectName__c, Automatically_Share__c FROM Shared_Files_Setting__mdt WHERE ObjectName__c IN: sObjectNames AND Used_For_Testing_Only__c = false];
        else sharedFilesSettings = [SELECT Id, ObjectName__c, Automatically_Share__c FROM Shared_Files_Setting__mdt WHERE ObjectName__c IN: sObjectNames]; 
        
        if(sharedFilesSettings == null || sharedFilesSettings.isEmpty()) return sharedFilesSettingsMap;
        for(Shared_Files_Setting__mdt setting: sharedFilesSettings)
        {
            sharedFilesSettingsMap.put(setting.ObjectName__c, setting);
        }
        return sharedFilesSettingsMap;
    }
    
    // Updates the Description of the Version of the Docuemnents
    public static void updateContentDescriptions(Map<Id,String> mapIdToDescription)
    {
        List<ContentVersion> theVersions = [SELECT Id, Description FROM ContentVersion WHERE Id IN: mapIdToDescription.keySet()]; 
        for(ContentVersion cd: theVersions)
        {
            cd.Description = mapIdToDescription.get(cd.Id);
        }
        update theVersions;
    }
    
    // inserts only the Shared Files for Records where the user has Read Access
    public static List<Shared_File__c> insertSharedFilesWithAccess(List<Shared_File__c> sharedFiles)
    {
        Set<Id> relatedRecordsIds = new Set<Id>(); 
        List<Shared_File__c> sharedFilesToInsert = new List<Shared_File__c>();
        for(Shared_File__c sf: sharedFiles) relatedRecordsIds.add(sf.RelatedRecordId__c); 
        List<UserRecordAccess> accessRecords = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN: relatedRecordsIds]; 
        Map<String, Boolean> mapRecordIdToAccess = new Map<String, Boolean>(); 
        for(UserRecordAccess ura: accessRecords) mapRecordIdToAccess.put(ura.RecordId, ura.HasEditAccess); 
        for(Shared_File__c sf: sharedFiles)
        {
            if(mapRecordIdToAccess.get(sf.RelatedRecordId__c) == true)
            {
                sharedFilesToInsert.add(sf);
            }
        }
        if(!sharedFilesToInsert.isEmpty()) insert sharedFilesToInsert; 
        return sharedFilesToInsert;
    }
    
    // Block access if Edit Access to related record is denied 
    public static void blockAccessIfRelatedNotEditable(List<Shared_File__c> sharedFiles)
    {
        Set<Id> relatedRecordsIds = new Set<Id>(); 
        for(Shared_File__c sf: sharedFiles) relatedRecordsIds.add(sf.RelatedRecordId__c); 
        List<UserRecordAccess> accessRecords = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN: relatedRecordsIds]; 
        Map<String, Boolean> mapRecordIdToAccess = new Map<String, Boolean>(); 
        for(UserRecordAccess ura: accessRecords) mapRecordIdToAccess.put(ura.RecordId, ura.HasEditAccess); 
        for(Shared_File__c sf: sharedFiles)
        {
            if(mapRecordIdToAccess.get(sf.RelatedRecordId__c) == false)
            {
                sf.addError('You do not have edit rights to Related Record: '+sf.RelatedRecordId__c);
            }
        }
    }
}