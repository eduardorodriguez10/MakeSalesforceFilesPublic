trigger onSharedFile on Shared_File__c (before insert, before update) {
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
    {
        // Mark items with errors if user doesn't have edit access to Related Record 
        if(Trigger.isUpdate) ContentService.blockAccessIfRelatedNotEditable(Trigger.new);
        
        // If shared_file has the Display Publicly Checked, then create Custom Distribution
        // If shared_file has the Display Publicly Unchecked, delete the Custom Distribution 
        // Update descriptions in the Document if Updated in the Shared_File__c record
        List<Shared_File__c> sharedFilesToShare = new List<Shared_File__c>(); 
        List<Shared_File__c> sharedFilesToUnshare = new List<Shared_File__c>(); 
        Map<Id,String> descriptionsToUpdate = new Map<Id,String>(); 
        
        for(Shared_File__c sf: Trigger.new)
        {
            System.debug('Checking Shared File with Display = '+sf.Display_In_Public_Site__c);
            Boolean oldValue; 
            String oldDescription;
            if(Trigger.isUpdate)
            {
                // If Updated, check if the Display Setting or the Description Changed
                Shared_File__c oldSf = Trigger.oldMap.get(sf.Id);
                oldValue = oldSf.Display_In_Public_Site__c;
                if(sf.Display_In_Public_Site__c == true && oldValue == false)
                {
                    sharedFilesToShare.add(sf);
                    descriptionsToUpdate.put(sf.ContentVersionId__c, sf.Description__c);
                }    
                
                if(sf.Display_In_Public_Site__c == false && oldValue == true) sharedFilesToUnshare.add(sf); 
                
                oldDescription = oldSf.Description__c; 
                if(oldDescription != sf.Description__c) descriptionsToUpdate.put(sf.ContentVersionId__c, sf.Description__c);
            }
            else
            {
                // Always execute the sharing logic if Inserted
                if(sf.Display_In_Public_Site__c == true) sharedFilesToShare.add(sf);
                if(sf.Display_In_Public_Site__c == false ) sharedFilesToUnshare.add(sf); 
            }
        }
        
        if(sharedFilesToShare != null && !sharedFilesToShare.isEmpty())
        {
            Set<Id> documentIds = new Set<Id>(); 
            Map<Id,Id> documentIdToVersion = new Map<Id,Id>(); 
            for(Shared_File__c sf: sharedFilesToShare)
            {
                documentIds.add(sf.ContentDocumentId__c); 
                documentIdToVersion.put(sf.ContentDocumentId__c, sf.ContentVersionId__c); 
            }
            
            // Create Content Distribution for the Files that need to be shared
            List<ContentDistribution> contentDistributions = ContentService.createOrRetrieveContentDistribution(documentIds, documentIdToVersion); 
            
            Map<Id,ContentDistribution> mapDocIdToContentDistribution = new Map<Id,ContentDistribution>(); 
            for(ContentDistribution cd: contentDistributions)
            {
                mapDocIdToContentDistribution.put(cd.ContentDocumentId, cd); 
            }
            
            // Update the Download_Link__c field from the newly generated Content Distribution
            for(Shared_File__c sf: sharedFilesToShare)
            {
                ContentDistribution thisCd =  mapDocIdToContentDistribution.get(sf.ContentDocumentId__c); 
                sf.Download_Link__c = thisCd.DistributionPublicUrl;
            }
        }
        
        if(sharedFilesToUnshare != null && !sharedFilesToUnshare.isEmpty())
        {
            // Remove Content Distributions if user desired to unshare
            Set<Id> documentIds = new Set<Id>(); 
            for(Shared_File__c sf: sharedFilesToUnshare)
            {
                documentIds.add(sf.ContentDocumentId__c); 
                sf.Download_Link__c = null; 
            }
            ContentService.deleteContentDistributions(documentIds);
        }
        
        // Update Descriptions as needed 
        if(descriptionsToUpdate != null && !descriptionsToUpdate.isEmpty()) ContentService.updateContentDescriptions(descriptionsToUpdate);
        
    }
}