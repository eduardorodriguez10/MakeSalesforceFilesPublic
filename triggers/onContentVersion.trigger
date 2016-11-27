trigger onContentVersion on ContentVersion (after insert, after update) {
	
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
    {
        // Share Content Records Publicly with a link if they are related to a Services_Contract__c record
        // then get the URL Link and store it in a Shared_File__c record
        
        SharedFileService sharedFilesToInsert = new SharedFileService(); 
        sharedFilesToInsert.buildSharedFiles(Trigger.new); 
        sharedFilesToInsert.insertSharedFilesWithAccess();
        
    }
}