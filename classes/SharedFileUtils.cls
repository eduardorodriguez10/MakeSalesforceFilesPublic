public class SharedFileUtils {
	
    // Returns a map of the ContentDocumentId to the LatestVersionId
    public static Map<Id,Id> getMapOfContentDocumentToLatestVersion(List<ContentVersion> docVersions)
    {
        // get the document Ids of the latest versions upserted
        // to identify if they are related to a service contract record
        Map<Id,Id> documentToVersionIdsOfLatestVersionsMap = new Map<Id,Id>();

        for(ContentVersion cv: docVersions)
        {
            // Get the new document versions if they are the latest
            if(cv.isLatest) documentToVersionIdsOfLatestVersionsMap.put(cv.ContentDocumentId, cv.Id);
        }
        
        return documentToVersionIdsOfLatestVersionsMap;
    }
    
    // Returns a Set of SObjectNames in the LinkedEntity of the ContentDocumentLink for all Content Documents in Set
    public static Set<String> getDocumentsSObjectNames(Set<Id> documentIds) 
    {
        Set<String> sObjectNames = new Set<String>(); 
        // query content documents to check if related to service contract
        List<ContentDocumentLink> allContentDocumentsLinks = [SELECT ContentDocument.title, ContentDocument.FileType, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: documentIds];
        
        if(allContentDocumentsLinks == null || allContentDocumentsLinks.isEmpty()) return sObjectNames; 
        
        for(ContentDocumentLink cdl: allContentDocumentsLinks)
        {
            // check if content is related to a SSP_Services_Contract__c record
            if(cdl.LinkedEntityId != null)
            {
                // Do not return the User SObjectName, we are not sharing documents per user
                if(cdl.LinkedEntityId.getSObjectType() != User.SObjectType)
                    sObjectNames.add(cdl.LinkedEntityId.getSObjectType().getDescribe().getName());
            }
        }
        
        return sObjectNames;
    }
    
    // It returns a map including al list of ContentVersions for each SObjectName
    public static Map<String,List<ContentVersion>> getSObjectNameToVersionsMap(List<ContentVersion> theVersions, Set<String> sObjectNames)
    {
        Map<String,List<ContentVersion>> sObjectNameToVersionsMap = new Map<String,List<ContentVersion>>(); 
        Map<Id,ContentVersion> mapIdToContentVersion = new Map<Id,ContentVersion>(theVersions);
        Map<Id,Id> docIdToVersionMap = SharedFileUtils.getMapOfContentDocumentToLatestVersion(theVersions); 
        Set<Id> theDocumentIds = docIdToVersionMap.keySet(); 
        
        List<ContentDocumentLink> allContentDocumentsLinks = [SELECT ContentDocument.title, ContentDocument.FileType, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: theDocumentIds];
        
        for(String sObjectName: sObjectNames)
        {
            for(ContentDocumentLink cdl: allContentDocumentsLinks)
            {
                // check if content is related to a SSP_Services_Contract__c record
                if(cdl.LinkedEntityId != null && cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == sObjectName)
                {
                    List<ContentVersion> loadedVersions = sObjectNameToVersionsMap.get(sObjectName); 
                    if(loadedVersions == null) loadedVersions = new List<ContentVersion>(); 
                    loadedVersions.add(mapIdToContentVersion.get(docIdToVersionMap.get(cdl.ContentDocumentId)));
                    sObjectNameToVersionsMap.put(sObjectName, loadedVersions);
                }
            }
        }
        return sObjectNameToVersionsMap;
    }
    
    // Returns a mapping of Document Ids to Document Links matching the names in the sObjectNames in the LinkedEntityId record
    public static Map<Id,ContentDocumentLink> getDocIdToContentDocumentLinksMap(Set<Id> documentIds, Set<String> sobjectNames)
    {

        // query content documents to check if related to service contract
        List<ContentDocumentLink> allContentDocumentsLinks = [SELECT ContentDocument.title, ContentDocument.FileType, ContentDocument.description,LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: documentIds];
        
        Map<Id,ContentDocumentLink> idToContentDocumentMap = new Map<Id,ContentDocumentLink>();
        
        System.debug(':::allContentDocuments = '+allContentDocumentsLinks);
        if(allContentDocumentsLinks != null && !allContentDocumentsLinks.isEmpty())
        {
            for(ContentDocumentLink cdl: allContentDocumentsLinks)
            {
                // if related added to the set and map for further processing
                if(cdl.LinkedEntityId != null)
                {
                    for(String sObjectName: sObjectNames)
                    {
                        System.debug('::: Checking if '+cdl.LinkedEntityId.getSObjectType()+' == '+Schema.getGlobalDescribe().get(sObjectName));
                        if(cdl.LinkedEntityId.getSObjectType() == Schema.getGlobalDescribe().get(sObjectName))
                            idToContentDocumentMap.put(cdl.ContentDocumentId, cdl);
                    }

                }
            }
        }
        
        System.debug(':::documentIdsOfServicesContractsFiles = '+idToContentDocumentMap.keySet());
        return idToContentDocumentMap;
    }
    
    // Returns any configured Shared_Files_Settings that match the sObjectName in the ObjectName__c field
    public static Map<String, Shared_Files_Setting__mdt> getSharedFileSettings(Set<String> sObjectNames)
    {
        Map<String,Shared_Files_Setting__mdt> sharedFilesSettingsMap = new Map<String,Shared_Files_Setting__mdt>();
        List<Shared_Files_Setting__mdt> sharedFilesSettings;
        if(!Test.isRunningTest()) sharedFilesSettings = [SELECT Id, ObjectName__c, Automatically_Share__c FROM Shared_Files_Setting__mdt WHERE ObjectName__c IN: sObjectNames AND Used_For_Testing_Only__c = false];
        else sharedFilesSettings = [SELECT Id, ObjectName__c, Automatically_Share__c FROM Shared_Files_Setting__mdt WHERE ObjectName__c IN: sObjectNames]; 
        
        if(sharedFilesSettings == null || sharedFilesSettings.isEmpty()) return sharedFilesSettingsMap;
        for(Shared_Files_Setting__mdt setting: sharedFilesSettings)
        {
            sharedFilesSettingsMap.put(setting.ObjectName__c, setting);
        }
        return sharedFilesSettingsMap;
    }
    
    // Updates the Description of the Version of the Docuemnents
    public static void updateContentDescriptions(Map<Id,String> mapIdToDescription)
    {
        List<ContentVersion> theVersions = [SELECT Id, Description FROM ContentVersion WHERE Id IN: mapIdToDescription.keySet()]; 
        for(ContentVersion cd: theVersions)
        {
            cd.Description = mapIdToDescription.get(cd.Id);
        }
        update theVersions;
    }
    
}