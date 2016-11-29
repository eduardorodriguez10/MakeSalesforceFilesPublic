public class ContentDistributions {
    
    private Set<Id> contentDocumentIds {get; set;}
    private List<ContentDistribution> theContentDistributions {get; set;}
    
    public ContentDistributions()
    {
        contentDocumentIds = new Set<Id>();
        theContentDistributions = new List<ContentDistribution>();
    }
    
    public ContentDistributions(List<ContentDistribution> pDistributions)
    {
        this.theContentDistributions = pDistributions; 
        this.contentDocumentIds = new Set<Id>(); 
        
        for(ContentDistribution cd: pDistributions)
        {
            this.contentDocumentIds.add(cd.ContentDocumentId);
        }
    }
    
    // gets the ContentDistributions of the Documents with the Ids in the DocumentIds
    public List<ContentDistribution> setDistributionsByDocumentIds(Set<Id> pContentDocumentIds)
    {
        this.contentDocumentIds = pContentDocumentIds; 
        this.theContentDistributions = [SELECT Id, ContentDocumentId, ContentVersionId, DistributionPublicUrl FROM ContentDistribution WHERE ContentDocumentId IN: this.contentDocumentIds];
        return this.theContentDistributions;
    }
    
    // Used To Create New Content Distributions
    public ContentDistributions(Map<Id,Id> pDocumentToVersionIdsOfLatestVersionsMap)
    {
        this.contentDocumentIds = pDocumentToVersionIdsOfLatestVersionsMap.keySet();
        this.theContentDistributions = new List<ContentDistribution>();
        // create content distribution and prepare for insert
        for(Id documentId: this.contentDocumentIds)
        {
            ContentDistribution cd = new ContentDistribution(); 
            cd.ContentVersionId = pDocumentToVersionIdsOfLatestVersionsMap.get(documentId);
            cd.Name = 'share_'+documentId;
            // do not send notification emails when files are viewed
            cd.PreferencesNotifyOnVisit = false; 
            cd.PreferencesNotifyRndtnComplete = false;
            // only insert it if it doesn't have a content distribution yet
            this.theContentDistributions.add(cd);
        }
    }
    
    public List<ContentDistribution> upsertContentDistributions()
    {
        if(this.theContentDistributions == null || this.theContentDistributions.isEmpty()) return null; 
        
        if(!this.theContentDistributions.isEmpty())
        {
            List<ContentDistribution> distributionsToInsert = new List<ContentDistribution>();
            List<ContentDistribution> distributionsToUpdate = new List<ContentDistribution>();
            for(ContentDistribution cd: this.theContentDistributions)
            {
                if(cd.Id == null) distributionsToInsert.add(cd); 
                else distributionsToUpdate.add(cd); 
            }
            if(!distributionsToInsert.isEmpty()) insert distributionsToInsert; 
            if(!distributionsToUpdate.isEmpty()) update distributionsToUpdate;
        }
        
        Map<Id,ContentDistribution> contentDistributionsMap = new Map<Id, ContentDistribution>(this.theContentDistributions);
        // update the Content Distributions with the newly generated URL
        this.theContentDistributions = [SELECT Id, ContentDocumentId, ContentVersionId, DistributionPublicUrl FROM ContentDistribution WHERE Id IN: contentDistributionsMap.keySet()];
        return this.theContentDistributions;
    }
    
    // Deletes all content distributions for the related content documents
    public void deleteContentDistributions()
    {       
        System.debug('::: Deleting Distributions :'+this.theContentDistributions);
        
        if(this.theContentDistributions == null || this.theContentDistributions.isEmpty()) return; 

        //delete only ContentDistributions that have been created in the database
        List<ContentDistribution> distributionsToDelete = new List<ContentDistribution>(); 
        
        for(ContentDistribution cd: this.theContentDistributions)
        {
            if(cd.Id != null) distributionsToDelete.add(cd); 
        }
        
        if(distributionsToDelete != null && !distributionsToDelete.isEmpty())
        {
            delete distributionsToDelete;
        }
        
        this.theContentDistributions = new List<ContentDistribution>();
        
    }
    
}