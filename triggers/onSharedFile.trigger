trigger onSharedFile on Shared_File__c (before insert, before update) {
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
    {
        SharedFileService.addErrorsIfUserDoesnotHaveAccessToRelatedRecord(Trigger.new); 

        
        // --- (1) Collect the Shared_File__c records that need to be shared
                // -- Display_In_Public_Site__c changed from false to true
                // Collect the Shared_File__C records that need to be unshared
                // -- Display_In_Public_Site__c changed from true to false
                // Collect the Shared_File__c records that have updated descriptions
                
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
                        descriptionsToUpdate.put(sf.ContentDocumentId__c, sf.Description__c);
                    }    
                    
                    // Get files that need to be unshared
                    if(sf.Display_In_Public_Site__c == false && oldValue == true) sharedFilesToUnshare.add(sf); 
                    
                    // Get files that need to have the description updated
                    oldDescription = oldSf.Description__c; 
                    if(oldDescription != sf.Description__c) descriptionsToUpdate.put(sf.ContentDocumentId__c, sf.Description__c);
                }
                else
                {
                    // Always execute the sharing logic if Inserted
                    if(sf.Display_In_Public_Site__c == true) sharedFilesToShare.add(sf);
                    if(sf.Display_In_Public_Site__c == false ) sharedFilesToUnshare.add(sf); 
                }
            }
        // --- (1)
        
        
        // --- (2) If any Shared_File__c records need to be created
        // ---Create Content Distributions and Update Shared_File__c Links
            if(sharedFilesToShare != null && !sharedFilesToShare.isEmpty())
            {
                SharedFileService.recreateDistributions(sharedFilesToShare); 
            }
        // --- (2)
        
        // (3) If any Shared_File__c records need to be unshared
        // Remove Content Distributions and Update Shared_File__c Links
            if(sharedFilesToUnshare != null && !sharedFilesToUnshare.isEmpty())
            {
                System.debug('Unsharing Records: '+sharedFilesToUnshare);
                SharedFileService.removeDistributions(sharedFilesToUnshare); 
                
            }
        // --- (3)
        
        // ---- (4) Update Descriptions as needed 
            if(descriptionsToUpdate != null && !descriptionsToUpdate.isEmpty())
            {
                System.debug('Updating descriptions: '+descriptionsToUpdate);
                SharedFileUtils.descriptionUpdatedOnSharedFile = true;
                SharedFileService.updateLatestVersionsDescriptions(descriptionsToUpdate); 
            }
        // ---- 
    }
}