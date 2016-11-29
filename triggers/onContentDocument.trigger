trigger onContentDocument on ContentDocument (after delete) {
	if(Trigger.isAfter && Trigger.isDelete)
    {
        // Delete Shared_File__c records when the attachment is deleted
        SharedFileService.deleteSharedFiles(Trigger.OldMap.keySet());

    }
}