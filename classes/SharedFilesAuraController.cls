public class SharedFilesAuraController {
	
	
    @auraEnabled
    public static List<Shared_File__c> returnRelatedSharedFiles(String pRecordId)
    {
        return [SELECT Id, 
                		ContentDocumentId__c, 
                		ContentVersionId__c, 
                		ContentDistributionId__c, 
                		Download_Link__c,
                		Description__c,
                		Display_In_Public_Site__c,
                		File_Name__c, 
                		File_Type__c FROM Shared_File__c WHERE RelatedRecordId__c =: pRecordId];
    }
    
    @auraEnabled
    public static List<Shared_File__c> updatedSharedFiles(List<Shared_File__c> sharedFiles, String pRecordId)
    {
        update sharedFiles;
        return [SELECT Id, 
                		ContentDocumentId__c, 
                		ContentVersionId__c, 
                		ContentDistributionId__c, 
                		Download_Link__c, 
                		Description__c,
                		Display_In_Public_Site__c,
                		File_Name__c, 
                		File_Type__c FROM Shared_File__c WHERE RelatedRecordId__c =: pRecordId];
    }
    
    @auraEnabled
    public static Boolean hasEditAccess(String pRecordId)
    {
        Boolean hasAccess = false; 
        try
        {
            hasAccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId =: pRecordId][0].HasEditAccess; 
        }
        catch(Exception e)
        {
            System.debug('Could not find UserRecordAccess: '+e.getMessage()); 
        }
        return hasAccess;
        
    }
}