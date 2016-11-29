trigger onContentVersion on ContentVersion (after insert, after update) {
	
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
    {
        ContentVersions updatedVersions = new ContentVersions(Trigger.new); 
        
        // ---- (1) If there are any existing Shared_File__c records, update the ContentVersionId__c field
        // with the field Id of the new Version
            List<Shared_File__c> existingSharedFilesRecords = updatedVersions.getExistingSharedFiles();
            if(existingSharedFilesRecords != null && !existingSharedFilesRecords.isEmpty())
            {
                // Update Existing Shared_File__c with new VersionId
                Map<Id,Id> documentToVersionIdsOfLatestVersionsMap = updatedVersions.getDocIdToContentVersionId();
                SharedFileService.updateVersionIdInSharedFiles(existingSharedFilesRecords, documentToVersionIdsOfLatestVersionsMap); 
            }
        // ---- (1)
        
        
        // ---- (2) Check if any Shared_File__c records need to be created and create them
            List<Shared_File__c> shareFilesToCreate = updatedVersions.getSharedFilesToCreate();
            if(shareFilesToCreate != null && !shareFilesToCreate.isEmpty())
            {
                // Create New Shared_File__c for Versions that do not have one
                SharedFileService.insertSharedFilesWithAccess(shareFilesToCreate);
            }
        // --- (2)
    }
}