public class ANM_Utils {
    
    // Get Id for Record Type with name pDeveloperName for the SObject with name pSObjectName
	public static Id getRecordTypeId(String pSObjectName, String pDeveloperName)
    {
        RecordType theRecordType; 
        try
        {
            theRecordType = [SELECT Id FROM RecordType WHERE sObjectType =: pSObjectName AND DeveloperName =: pDeveloperName LIMIT 1];
        }
        catch (Exception e)
        {
            return null;
        }

        return theRecordType.Id;
    }
}