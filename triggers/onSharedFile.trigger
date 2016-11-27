trigger onSharedFile on Shared_File__c (before insert, before update) {
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
    {
        SharedFileService allSharedFiles = new SharedFileService(Trigger.new); 
        
        // Mark items with errors if user doesn't have edit access to Related Record 
        allSharedFiles.blockAccessIfRelatedNotEditable();
        
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
                
                // Get files that need to be unshared
                if(sf.Display_In_Public_Site__c == false && oldValue == true) sharedFilesToUnshare.add(sf); 
                
                // Get files that need to have the description updated
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
        
        // Create Content Distributions and Update Shared_File__c Links
        if(sharedFilesToShare != null && !sharedFilesToShare.isEmpty())
        {
            SharedFileService filesToShare = new SharedFileService(sharedFilesToShare); 
            filesToShare.createContentDistributions();
        }
        
        // Remove Content Distributions and Update Shared_File__c Links
        if(sharedFilesToUnshare != null && !sharedFilesToUnshare.isEmpty())
        {
            SharedFileService filesToUnshare = new SharedFileService(sharedFilesToShare); 
            filesToUnshare.removeDistributions();
        }
        
        // Update Descriptions as needed 
        if(descriptionsToUpdate != null && !descriptionsToUpdate.isEmpty())
        {
            SharedFileUtils.updateContentDescriptions(descriptionsToUpdate);
        }
    }
}