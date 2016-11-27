trigger onContentVersion on ContentVersion (after insert, after update) {
	
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
    {
        // Share Content Records Publicly with a link if they are related to a Services_Contract__c record
        // then get the URL Link and store it in a Shared_File__c record
        
        // Returns a map of the content document Id to the latest version
        Map<Id,Id> documentToVersionIdsOfLatestVersionsMap = ContentService.getMapOfContentDocumentToLatestVersion(Trigger.new);
        
        // Get the SObject Names of the Related Objects
        Set<String> sObjectNames = ContentService.getDocumentsSObjectNames(documentToVersionIdsOfLatestVersionsMap.keySet()); 
        
        // Check if SObject Names have Settings Configured for Sharing
        Map<String, Shared_Files_Setting__mdt> sharedFileSettings = ContentService.getSharedFileSettings(sObjectNames);
        
        // Check if there are any records that need to be processed and create Shared_File__c records as needed
        if(sharedFileSettings != null && !sharedFileSettings.isEmpty())
        {
            Map<String,List<ContentVersion>> mapSObjectNameToListVersions = ContentService.getSObjectNameToVersionsMap(Trigger.new, sObjectNames); 
            Map<Id,ContentDocumentLink> mapDocIdToCDLink = ContentService.getDocIdToContentDocumentLinksMap(documentToVersionIdsOfLatestVersionsMap.keySet(), sObjectNames); 
            
            for(String sObjectName: mapSObjectNameToListVersions.keySet())
            {
                ContentService.createShareFileRecords(mapSObjectNameToListVersions.get(sObjectName), mapDocIdToCDLink, sharedFileSettings.get(sObjectName));
            }
        }
    }
}