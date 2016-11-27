public class SharedFileService {
    
    private List<Shared_File__c> theSharedFiles {get; set;}
    
    public SharedFileService()
    {
        theSharedFiles = new List<Shared_File__c>();
    }
    
    public SharedFileService(List<Shared_File__c> pSharedFiles)
    {
        this.theSharedFiles = pSharedFiles; 
    }
    
    // Creates new Shared_File__c records for Versions without a Shared_File__c
    // Updates existing Shared_File__c records with Updated Information from Versions if Existing
    public void buildSharedFiles(List<ContentVersion> theVersions)
    {
        // Returns a map of the content document Id to the latest version
        Map<Id,Id> documentToVersionIdsOfLatestVersionsMap = SharedFileUtils.getMapOfContentDocumentToLatestVersion(theVersions);
        
        // Get the SObject Names of the Related Objects
        Set<String> sObjectNames = SharedFileUtils.getDocumentsSObjectNames(documentToVersionIdsOfLatestVersionsMap.keySet()); 
        
        // Check if SObject Names have Settings Configured for Sharing
        Map<String, Shared_Files_Setting__mdt> sharedFileSettings = SharedFileUtils.getSharedFileSettings(sObjectNames);
        
        // Check if there are any records that need to be processed and create Shared_File__c records as needed
        if(sharedFileSettings != null && !sharedFileSettings.isEmpty())
        {
            Map<String,List<ContentVersion>> mapSObjectNameToListVersions = SharedFileUtils.getSObjectNameToVersionsMap(theVersions, sObjectNames); 
            Map<Id,ContentDocumentLink> mapDocIdToCDLink = SharedFileUtils.getDocIdToContentDocumentLinksMap(documentToVersionIdsOfLatestVersionsMap.keySet(), sObjectNames); 
            
            List<Shared_File__c> sharedFilesBuilt = new List<Shared_File__c>(); 
            List<Shared_File__c> existingFiles = [SELECT Id, Display_In_Public_Site__c, ContentVersionId__c, ContentDocumentId__c, File_Name__c, File_Type__c, RelatedRecordId__c, Description__c FROM Shared_File__c WHERE ContentDocumentId__c IN: mapDocIdToCDLink.keySet()];
            Map<Id,Shared_File__c> mapDocIdToSharedFile = new Map<Id,Shared_File__c>();
            for(Shared_File__c existingFile: existingFiles)
            {
                mapDocIdToSharedFile.put(existingFile.ContentDocumentId__c, existingFile);
            }
            
            for(String objectName: mapSObjectNameToListVersions.keySet())
            {
                List<ContentVersion> contentVersions = mapSObjectNameToListVersions.get(objectName);
                for(ContentVersion cv: contentVersions)
                {
                    Shared_File__c sharedFile = mapDocIdToSharedFile.get(cv.ContentDocumentId);
                    if(sharedFile == null) sharedFile = new Shared_File__c(); 
                    sharedFile.Display_In_Public_Site__c = sharedFileSettings.get(objectName).Automatically_Share__c; 
                    sharedFile.ContentVersionId__c = cv.Id; 
                    sharedfile.ContentDocumentId__c = cv.ContentDocumentId;
                    ContentDocumentLink theDocumentLink = mapDocIdToCDLink.get(cv.ContentDocumentId);
                    sharedfile.File_Name__c = theDocumentLink.ContentDocument.title;
                    sharedfile.File_Type__c = theDocumentLink.ContentDocument.fileType;
                    sharedFile.RelatedRecordId__c = theDocumentLink.LinkedEntityId; 
                    sharedFile.Description__c = theDocumentLink.ContentDocument.description;
                    sharedFilesBuilt.add(sharedFile);
                }
            }
            
            this.theSharedFiles = sharedFilesBuilt;
        }
    }
        
    // inserts only the Shared Files for Records where the user has Read Access
    public void insertSharedFilesWithAccess()
    {
        Set<Id> relatedRecordsIds = new Set<Id>(); 
        List<Shared_File__c> sharedFilesToInsert = new List<Shared_File__c>();
        List<Shared_File__c> filesNoPreviouslyCreated = new List<Shared_File__c>(); 
        
        for(Shared_File__c sf: this.theSharedFiles)
        {
            if(sf.Id == null) filesNoPreviouslyCreated.add(sf);
        }
        
        for(Shared_File__c sf: this.theSharedFiles) relatedRecordsIds.add(sf.RelatedRecordId__c); 
        List<UserRecordAccess> accessRecords = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN: relatedRecordsIds]; 
        Map<String, Boolean> mapRecordIdToAccess = new Map<String, Boolean>(); 
        for(UserRecordAccess ura: accessRecords) mapRecordIdToAccess.put(ura.RecordId, ura.HasEditAccess); 
        
        for(Shared_File__c sf: filesNoPreviouslyCreated)
        {
            if(mapRecordIdToAccess.get(sf.RelatedRecordId__c) == true)
            {
                sharedFilesToInsert.add(sf);
            }
        }
        
        if(!sharedFilesToInsert.isEmpty()) insert sharedFilesToInsert; 
    }
    
    // Creates ContentDistributions for the SharedFiles and Updates the Shared Files Links with the ContentDistribution
    public List<ContentDistribution> createContentDistributions()
    {
        Set<Id> documentIds = new Set<Id>(); 
        Map<Id,Id> documentIdToVersion = new Map<Id,Id>(); 
        for(Shared_File__c sf: this.theSharedFiles)
        {
            documentIds.add(sf.ContentDocumentId__c); 
            documentIdToVersion.put(sf.ContentDocumentId__c, sf.ContentVersionId__c); 
        }
        
        ContentDistributionService distributionService = new ContentDistributionService(documentIds);
        
        // Delete Previous Destributions
        distributionService.deleteContentDistributions(); 
        // Recreate Distributions for New Versions
        distributionService.buildContentDistributions(documentIdToVersion); 
        // Insert Distributions
        List<ContentDistribution> contentDistributions = distributionService.insertContentDistributions(); 
                
        Map<Id,ContentDistribution> mapDocIdToContentDistribution = new Map<Id,ContentDistribution>(); 
        for(ContentDistribution cd: contentDistributions)
        {
            mapDocIdToContentDistribution.put(cd.ContentDocumentId, cd); 
        }
        
        // Update the Download_Link__c field from the newly generated Content Distribution
        for(Shared_File__c sf: this.theSharedFiles)
        {
            ContentDistribution thisCd =  mapDocIdToContentDistribution.get(sf.ContentDocumentId__c); 
            sf.Download_Link__c = thisCd.DistributionPublicUrl;
        }
        
        return contentDistributions;
    }
    
    // Removes teh ContentDistributions for the Shared Files
    public void removeDistributions()
    {
        // Remove Content Distributions if user desired to unshare
        Set<Id> documentIds = new Set<Id>(); 
        for(Shared_File__c sf: this.theSharedFiles)
        {
            documentIds.add(sf.ContentDocumentId__c); 
            sf.Download_Link__c = null; 
        }
        ContentDistributionService deletedDistributions = new ContentDistributionService(documentIds); 
        deletedDistributions.deleteContentDistributions();
    }
    
    // Block access if Edit Access to related record is denied 
    public void blockAccessIfRelatedNotEditable()
    {
        Set<Id> relatedRecordsIds = new Set<Id>(); 
        for(Shared_File__c sf: this.theSharedFiles) relatedRecordsIds.add(sf.RelatedRecordId__c); 
        List<UserRecordAccess> accessRecords = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN: relatedRecordsIds]; 
        Map<String, Boolean> mapRecordIdToAccess = new Map<String, Boolean>(); 
        for(UserRecordAccess ura: accessRecords) mapRecordIdToAccess.put(ura.RecordId, ura.HasEditAccess); 
        for(Shared_File__c sf: this.theSharedFiles)
        {
            if(mapRecordIdToAccess.get(sf.RelatedRecordId__c) == false)
            {
                sf.addError('You do not have edit rights to Related Record: '+sf.RelatedRecordId__c);
            }
        }
    }
}