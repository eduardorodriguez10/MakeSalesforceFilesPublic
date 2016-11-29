public class ContentVersions {
    
    private List<ContentVersion> latestContentVersions {get; set;}
    private List<Shared_File__c> existingSharedFiles {get; set;}
    private List<Shared_File__c> sharedFilesToCreate {get; set;}
    private Set<Id> theDocumentIds {get; set;}
    private Map<Id, Id> mapDocIdToContentVersionId {get; set;}
    
    public ContentVersions (List<ContentVersion> contentVersions)
    {
        this.latestContentVersions = contentVersions;
    }
    
    public ContentVersions()
    {
        this.latestContentVersions = new List<ContentVersion> (); 
        this.theDocumentIds = new Set<Id>();
    }
    
    public void setContentVersionsByDocumentIds(Set<Id> documentIds)
    {
        this.latestContentVersions = [SELECT Id, Description, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN: documentIds AND isLatest = true]; 
        this.theDocumentIds = documentIds;
    }
    
    private void setDocumentIds()
    {
        this.theDocumentIds = new Set<Id>(); 
        
        for(ContentVersion cv: this.latestContentVersions)
        {
            this.theDocumentIds.add(cv.ContentDocumentId); 
        }
    }
    
    private void setDocIdToContentVersionId()
    {
        this.mapDocIdToContentVersionId = new Map<Id, Id>(); 
        for(ContentVersion cv: this.latestContentVersions)
        {
            this.mapDocIdToContentVersionId.put(cv.ContentDocumentId, cv.Id);
        }
    }
    
    public Set<Id> getTheDocumentIds()
    {
        if(this.theDocumentIds == null) this.setDocumentIds();
        return this.theDocumentIds;
    }
    
    public Map<Id,Id> getDocIdToContentVersionId()
    {
        if(this.mapDocIdToContentVersionId == null) this.setDocIdToContentVersionId();
        return this.mapDocIdToContentVersionId;
    }
    
    // Updates Descriptions of the Latest Versions of the Document
    public void updateDescriptions(Map<Id, String> docIdToDescription)
    {
        for(ContentVersion cv: this.latestContentVersions)
        {
            String newDescription = docIdToDescription.get(cv.ContentDocumentId); 
            if(newDescription != null) cv.Description = newDescription;
        }
    }
    
    public List<ContentVersion> upsertContentVersions()
    {
        if(this.latestContentVersions != null && !this.latestContentVersions.isEmpty()) upsert this.latestContentVersions;
        return this.latestContentVersions;
    }
    
    // Returns the Shared_Files__c that exist for the Documents of the Versions
    public List<Shared_File__c> getExistingSharedFiles()
    {
        if(this.existingSharedFiles != null) return this.existingSharedFiles; 
        this.getTheDocumentIds();
        this.existingSharedFiles = [SELECT Id, Display_In_Public_Site__c, ContentVersionId__c, ContentDocumentId__c, File_Name__c, File_Type__c, RelatedRecordId__c, Description__c FROM Shared_File__c WHERE ContentDocumentId__c IN: this.theDocumentIds];
        return this.existingSharedFiles;
    }
    
    // Returns the Shared_File__c that need to be created for the Documents in the Versions
    public List<Shared_File__c> getSharedFilesToCreate()
    {
        this.sharedFilesToCreate  = new List<Shared_File__c>();
        // Returns a map of the content document Id to the latest version
        Map<Id,Id> documentToVersionIdsOfLatestVersionsMap = this.getDocIdToContentVersionId();
        
        // Get the SObject Names of the Related Objects
        Set<String> sObjectNames = SharedFileUtils.getDocumentsSObjectNames(documentToVersionIdsOfLatestVersionsMap.keySet()); 
        
        // Check if SObject Names have Settings Configured for Sharing
        Map<String, Shared_Files_Setting__mdt> sharedFileSettings = SharedFileUtils.getSharedFileSettings(sObjectNames);
        
        // Check if there are any records that need to be processed and create Shared_File__c records as needed
        if(sharedFileSettings != null && !sharedFileSettings.isEmpty())
        {
            Map<String,List<ContentVersion>> mapSObjectNameToListVersions = SharedFileUtils.getSObjectNameToVersionsMap(this.latestContentVersions, sObjectNames); 
            Map<Id,ContentDocumentLink> mapDocIdToCDLink = SharedFileUtils.getDocIdToContentDocumentLinksMap(documentToVersionIdsOfLatestVersionsMap.keySet(), sObjectNames); 
            List<Shared_File__c> sharedFilesBuilt = new List<Shared_File__c>(); 
            
            // First check if versions currently have Shared_File__c records
            this.existingSharedFiles = this.getExistingSharedFiles();
            
            Map<Id,Shared_File__c> mapDocIdToExistingSharedFile = new Map<Id,Shared_File__c>();
            
            for(Shared_File__c existingFile: this.existingSharedFiles)
            {
                mapDocIdToExistingSharedFile.put(existingFile.ContentDocumentId__c, existingFile);
            }
            
            // Crate Shared_File__c records for the configured SObjects in the Metadata Type
            for(String objectName: mapSObjectNameToListVersions.keySet())
            {
                List<ContentVersion> contentVersions = mapSObjectNameToListVersions.get(objectName);
                
                for(ContentVersion cv: contentVersions)
                {
                    // Only Build if It Doesn't Have One Already
                    if(mapDocIdToExistingSharedFile.get(cv.ContentDocumentId) == null)
                    {
                        Shared_File__c sharedFile = new Shared_File__c(); 
                        // Update Properties of Shared File Record
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
            }
            
            this.sharedFilesToCreate = sharedFilesBuilt;
            
        }
        return this.sharedFilesToCreate;
    }
    
}