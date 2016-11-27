public class ContentDistributionService {
	
    private Set<Id> contentDocumentIds {get; set;}
    private Map<Id,Id> documentToVersionIdsOfLatestVersionsMap {get; set;}
    private List<ContentDistribution> theContentDistributions {get; set;}
    
    public ContentDistributionService(Set<Id> pContentDocumentIds)
    {
        this.contentDocumentIds = pContentDocumentIds; 
        this.theContentDistributions = [SELECT Id, ContentDocumentId, ContentVersionId, DistributionPublicUrl FROM ContentDistribution WHERE ContentDocumentId IN: this.contentDocumentIds];
    }
    
    public void buildContentDistributions(Map<Id,Id> pDocumentToVersionIdsOfLatestVersionsMap)
    {
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
    
    public List<ContentDistribution> insertContentDistributions()
    {
        if(!this.theContentDistributions.isEmpty()) insert this.theContentDistributions; 
        Map<Id,ContentDistribution> contentDistributionsMap = new Map<Id, ContentDistribution>(this.theContentDistributions);
        this.theContentDistributions = [SELECT Id, ContentDocumentId, ContentVersionId, DistributionPublicUrl FROM ContentDistribution WHERE Id IN: contentDistributionsMap.keySet()];
        return this.theContentDistributions;
    }
    
    // Deletes all content distributions for the related content documents
    public void deleteContentDistributions()
    {       

        if(this.contentDocumentIds == null || this.contentDocumentIds.isEmpty()) return; 

        //check if there are previous shares for this document
        List<ContentDistribution> previousCDs = [SELECT Id, ContentDocumentId FROM ContentDistribution WHERE ContentDocumentId IN: this.contentDocumentIds];
        if(previousCDs != null && !previousCDs.isEmpty())
        {
            // delete previous shares to make sure only the latest version is shared
            delete previousCDs;
        }
    }
    
}