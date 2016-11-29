public class SharedFileService {
    
    // Adds errors to Shared_File__c if current user does not have Edit Access to Related Record
    public static void addErrorsIfUserDoesnotHaveAccessToRelatedRecord(List<Shared_File__c> pSharedFiles)
    {
        SharedFiles allSharedFiles = new SharedFiles(Trigger.new); 
        
        // Mark items with errors if user doesn't have edit access to Related Record 
        allSharedFiles.blockAccessIfRelatedNotEditable();
    }
    
    // deletes and recreates the ContentDistributions related to the Shared_File__c records
    public static List<ContentDistribution> recreateDistributions(List<Shared_File__c> pSharedFiles)
    {
        SharedFiles filesToShare = new SharedFiles(pSharedFiles); 
        // Remove any old distributions for the same documents
        filesToShare.removeDistributions();
        // Recreate the distributions with the new versions
        return filesToShare.createContentDistributions();
    }

    // deletes the ContentDistributions for Shared_file__c records and clears the URL Link
    public static void removeDistributions(List<Shared_File__c> pSharedFiles)
    {
        SharedFiles filesToUnshare = new SharedFiles(pSharedFiles); 
        filesToUnshare.clearLinks();
        filesToUnshare.removeDistributions();
    }
    
    // Updates the description of the Latest Version of the Documents in the Map KeySet with the Value of the Map
    public static void updateLatestVersionsDescriptions(Map<Id, String> pDocumentIdsToDescriptionsMap)
    {
        ContentVersions latestVersionsToUpdateDescription = new ContentVersions(); 
        latestVersionsToUpdateDescription.setContentVersionsByDocumentIds(pDocumentIdsToDescriptionsMap.keySet());
        latestVersionsToUpdateDescription.updateDescriptions(pDocumentIdsToDescriptionsMap);
        latestVersionsToUpdateDescription.upsertContentVersions();
    }
    
    // Updates the ContentVersionId__c field of the Shared_File__c record with the Id of the Version in the value of the Map
    public static List<Shared_File__c> updateVersionIdInSharedFiles(List<Shared_File__c> pSharedFiles, Map<Id,Id> documentToVersionIdsOfLatestVersionsMap)
    {
        SharedFiles existingSharedFiles = new SharedFiles(pSharedFiles); 
        existingSharedFiles.updateVersionIds(documentToVersionIdsOfLatestVersionsMap); 
        // Don't update the Shared_File__c records if the description was updated through them
        if(!SharedFileUtils.descriptionUpdatedOnSharedFile) return existingSharedFiles.upsertAll(); 
        return null;
    }
    
    // Inserts only Shared_File__c where the logged in user has Edit Access to the Related Record
    public static List<Shared_File__c> insertSharedFilesWithAccess(List<Shared_File__c> pSharedFiles)
    {
        SharedFiles sharedFilesToInsert = new SharedFiles(pSharedFiles); 
        return sharedFilesToInsert.insertSharedFilesWithAccess();
    }
    
    // Deletes the Shared_File__c records for the Documents in the Id Set
    public static void deleteSharedFiles(Set<Id> pDocumentIds)
    {
        // Get Any Shared_File__c records for these documents
        SharedFiles existingSharedFiles = new SharedFiles(); 
        existingSharedFiles.setSharedFilesByDocumentId(pDocumentIds); 
        existingSharedFiles.deleteAll();
    }
    
    // Marks the Display_In_Public_Site__c checkbox to true of the Shared_File__c records of the Set Id
    public static void unshareSharedFiles(Set<Id> pDocumentIds)
    {
        // Get Any Shared_File__c records for these documents
        SharedFiles existingSharedFiles = new SharedFiles(); 
        existingSharedFiles.setSharedFilesByDocumentId(pDocumentIds); 
        // Clear the Download_Link__c URL
        existingSharedFiles.clearLinks(); 
        // Mark the files as not shared
        existingSharedFiles.unshare(); 
        // Udate them all 
        if(!SharedFileUtils.distributionDeletedBySharedFile) existingSharedFiles.upsertAll();
    }
    
    // Marks the Display_In_Public_Site__c checkbox to true of the Shared_File__c records of the Set Id
    public static void reshareSharedFiles(Set<Id> pDocumentIds)
    {
        // Get Any Shared_File__c records for these documents
        SharedFiles existingSharedFiles = new SharedFiles(); 
        existingSharedFiles.setSharedFilesByDocumentId(pDocumentIds); 
        // Clear the Download_Link__c URL
        existingSharedFiles.clearLinks(); 
        // Mark the files as not shared
        existingSharedFiles.share(); 
        // Udate them all 
        if(!SharedFileUtils.distributionDeletedBySharedFile) existingSharedFiles.updateAll();
        
        
    }
    
}