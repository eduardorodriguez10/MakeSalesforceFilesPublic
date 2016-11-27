trigger onContentDocument on ContentDocument (after delete) {
	if(Trigger.isAfter && Trigger.isDelete)
    {
        // Delete Shared_File__c records when the attachment is deleted
        Set<Id> deletedDocumentIds = new Set<Id>();
        // get files of Services Contracts
        for(ContentDocument cd: Trigger.old)
        {
           deletedDocumentIds.add(cd.Id);
        }
        
        // delete the Shared_File__c records related to the deleted Content Distributions
        if(deletedDocumentIds != null && !deletedDocumentIds.isEmpty())
        {
            //Query the deleted records that are related to a Services_Contract__c
            List<Shared_File__c> relatedSharedFiles = [SELECT Id FROM Shared_File__c WHERE ContentDocumentId__c IN: deletedDocumentIds];
            if(relatedSharedFiles != null && !relatedSharedFiles.isEmpty()) delete relatedSharedFiles; 
        }
    }
}