public class SharedFiles {
    
    private List<Shared_File__c> theSharedFiles {get; set;}
    
    public SharedFiles()
    {
        theSharedFiles = new List<Shared_File__c>();
    }
    
    public SharedFiles(List<Shared_File__c> pSharedFiles)
    {
        this.theSharedFiles = pSharedFiles; 
    }
    
    // gets the Shared_File__c records of the documentIds Set
    public List<Shared_File__c> setSharedFilesByDocumentId(Set<Id> documentIds)
    {
        this.theSharedFiles = [SELECT Id, Display_In_Public_Site__c, ContentVersionId__c, ContentDocumentId__c, File_Name__c, File_Type__c, RelatedRecordId__c, Description__c FROM Shared_File__c WHERE ContentDocumentId__c IN: documentIds];
        return this.theSharedFiles;
    }
        
    // inserts only the Shared Files for Records where the user has Read Access
    public List<Shared_File__c> insertSharedFilesWithAccess()
    {
        Set<Id> relatedRecordsIds = new Set<Id>(); 
        List<Shared_File__c> sharedFilesToInsert = new List<Shared_File__c>();
        List<Shared_File__c> filesNoPreviouslyCreated = new List<Shared_File__c>(); 
        
        // get files that do not exist in the database
        for(Shared_File__c sf: this.theSharedFiles)
        {
            if(sf.Id == null) filesNoPreviouslyCreated.add(sf);
        }
        
        // Get the UserRecordAccess for all related Records
        for(Shared_File__c sf: this.theSharedFiles) relatedRecordsIds.add(sf.RelatedRecordId__c); 
        List<UserRecordAccess> accessRecords = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN: relatedRecordsIds]; 
        Map<String, Boolean> mapRecordIdToAccess = new Map<String, Boolean>(); 
        for(UserRecordAccess ura: accessRecords) mapRecordIdToAccess.put(ura.RecordId, ura.HasEditAccess); 
        
        // Insert Shared_File__c files if user has edit access to Related Record
        for(Shared_File__c sf: filesNoPreviouslyCreated)
        {
            if(mapRecordIdToAccess.get(sf.RelatedRecordId__c) == true)
            {
                sharedFilesToInsert.add(sf);
            }
        }
        
        if(!sharedFilesToInsert.isEmpty()) insert sharedFilesToInsert; 
        return sharedFilesToInsert;
    }


    public List<Shared_File__c> upsertAll()
    {
        if(!this.theSharedFiles.isEmpty()) upsert this.theSharedFiles;
        return this.theSharedFiles;
        
    }
    
    public List<Shared_File__c> updateAll()
    {
        if(!this.theSharedFiles.isEmpty()) update this.theSharedFiles;
        return this.theSharedFiles;
        
    }
    
    // Creates ContentDistributions for the SharedFiles and Updates the Shared Files Links with the ContentDistribution
    public List<ContentDistribution> createContentDistributions()
    {
        if(this.theSharedFiles == null || this.theSharedFiles.isEmpty()) return null; 
        
        Set<Id> documentIds = new Set<Id>(); 
        Map<Id,Id> documentIdToVersion = new Map<Id,Id>(); 
        for(Shared_File__c sf: this.theSharedFiles)
        {
            documentIds.add(sf.ContentDocumentId__c); 
            documentIdToVersion.put(sf.ContentDocumentId__c, sf.ContentVersionId__c); 
        }
        
        // Recreate Distributions for New Versions
        ContentDistributions distributionsToRecreate = new ContentDistributions(); 
        distributionsToRecreate.createContentDistributions(documentIdToVersion); 
        
        // Insert Distributions
        List<ContentDistribution> contentDistributions = distributionsToRecreate.upsertContentDistributions(); 
                
        Map<Id,ContentDistribution> mapDocIdToContentDistribution = new Map<Id,ContentDistribution>(); 
        for(ContentDistribution cd: contentDistributions)
        {
            mapDocIdToContentDistribution.put(cd.ContentDocumentId, cd); 
        }
        
        // Update the Download_Link__c field with the newly generated Content Distribution URL
        for(Shared_File__c sf: this.theSharedFiles)
        {
            ContentDistribution thisCd =  mapDocIdToContentDistribution.get(sf.ContentDocumentId__c); 
            sf.ContentDistributionId__c = thisCd.Id;
            sf.Download_Link__c = thisCd.DistributionPublicUrl;
        }
        
        return contentDistributions;
    }
    
    // Updates the VersionIds of the Shared_File__c records
    public void updateVersionIds(Map<Id,Id> docIdToVersionId)
    {
        if(this.theSharedFiles == null || this.theSharedFiles.isEmpty()) return; 
        
        Map<Id,Shared_File__c> mapDocIdToSharedFile = new Map<Id,Shared_File__c>(); 
        for(Shared_File__c sf: this.theSharedFiles)
        {
            mapDocIdToSharedFile.put(sf.ContentDocumentId__c, sf);
        }
        for(Id docId: docIdToVersionId.keySet())
        {
            Shared_File__c aSf = mapDocIdToSharedFile.get(docId); 
            if(aSf != null) aSf.ContentVersionId__c = docIdToVersionId.get(docId); 
        }
    }
    
    
    public void deleteAll()
    {
        if(this.theSharedFiles == null || this.theSharedFiles.isEmpty()) return; 
        
        delete this.theSharedFiles;
    }
    
    // Marks the Display_In_Public_Site__c field to false
    public void unshare()
    {
        if(this.theSharedFiles == null || this.theSharedFiles.isEmpty()) return; 
        
        for(Shared_File__c sf: this.theSharedFiles)
        {
            sf.Display_In_Public_Site__c = false; 
        }
    }
    
    // Marks the Display_In_Public_Site__c field to true
    public void share()
    {
        if(this.theSharedFiles == null || this.theSharedFiles.isEmpty()) return; 
        
        for(Shared_File__c sf: this.theSharedFiles)
        {
            sf.Display_In_Public_Site__c = true; 
        }
    }
    
    // Sets the Download_Link__c field to null
    public void clearLinks()
    {
        if(this.theSharedFiles == null || this.theSharedFiles.isEmpty()) return; 
        
        for(Shared_File__c sf: this.theSharedFiles)
        {
            sf.Download_Link__c = null; 
        }
    }
    
    // Deletes the ContentDistributions for the Shared Files
    public void removeDistributions()
    {
        System.debug(':::removing Distributions for: '+this.theSharedFiles);
        if(this.theSharedFiles == null || this.theSharedFiles.isEmpty()) return; 
        // Clear the Download_Link for all Shared_File__c records
        this.clearLinks(); 
        
        Set<Id> documentIds = new Set<Id>(); 
        for(Shared_File__c sf: this.theSharedFiles)
        {
            documentIds.add(sf.ContentDocumentId__c); 
        }
        // Delete the ContentDistributions
        ContentDistributions distributionsToDelete = new ContentDistributions(); 
        distributionsToDelete.setDistributionsByDocumentIds(documentIds);
        distributionsToDelete.deleteContentDistributions();
    }
    
    // Add Error to Shared_File__c record if user doesn't have edit access to the related record
    public void blockAccessIfRelatedNotEditable()
    {
        if(this.theSharedFiles == null || this.theSharedFiles.isEmpty()) return; 
        
        // Get UserRecordAccess for all related records
        Set<Id> relatedRecordsIds = new Set<Id>(); 
        for(Shared_File__c sf: this.theSharedFiles) relatedRecordsIds.add(sf.RelatedRecordId__c); 
        List<UserRecordAccess> accessRecords = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN: relatedRecordsIds]; 
        Map<String, Boolean> mapRecordIdToAccess = new Map<String, Boolean>(); 
        for(UserRecordAccess ura: accessRecords) mapRecordIdToAccess.put(ura.RecordId, ura.HasEditAccess); 
        // Add Error if user doesn't have access to related record
        for(Shared_File__c sf: this.theSharedFiles)
        {
            if(mapRecordIdToAccess.get(sf.RelatedRecordId__c) == false)
            {
                sf.addError('You do not have edit rights to Related Record: '+sf.RelatedRecordId__c);
            }
        }
    }
     
}