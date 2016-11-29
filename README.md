Automatically Share Salesforce Files and make them publicly available (Lightning Experience)
====================================

This application can be used to automatically share Salesforce Files that are related to records. It creates a content distribution record to make the file publicly available using an URL. 

How it works
------------

1. When a Salesforce File is uploaded and it is related to a record in Salesforce, the app checks the Shared_Files_Setting__mdt Metadata Type to see if the related SObject has been configured to publicly share these files. 
2. If a Shared_Files_Setting__mdt record exists for the related SObject, the app creates a Shared_File__c and stores the record Id of the related record in the RelatedRecordId__c field of the Share_File__c record. In the Shared_Files_Setting__mdt custom metadata record, you can specify if you want these files to be shared automatically using the Automatically_Share__c field. If this field is not selected, the user has the option to later share these files using the Lightning Component in the Record Page.
3. The files are shared by a trigger on the Shared_File__c object that creates ContentDistribution records for the files and stores the URL in the Download_Link__c URL field of the Shared_File__c record.
4. A Lightning Component is used to update these settings, remove sharing, update descriptions, etc. 

Dependencies
------------

1. The application uses some classes from https://github.com/DouglasCAyers/sfdc-convert-attachments-to-chatter-files from Douglas C Ayers to convert Attachments to Salesforce Files, which simplifies the Unit Testing. These classes requires Enhanced Notes enabled in the Salesforce Org. 
2. MyDomain is enabled for the Org.


Installation
-------------
1. Confirm Enhanced Notes are enabled, Lightning Experience is enabled and MyDomain has been configured. 
2. Deploy from github. 

Configuration
-------------
1. Create a Shared_Files_Setting__mdt record for each SObject that will contain attachments that you wish to share. In the ObjectName__c enter the SObject Name, such as ‘Account’ or ‘Project__c’. If you want these files to be shared automatically when the attachment is uploaded, check the Automatically_Share__c checkbox. The Used_For_Testing_Only__c checkbox is used to create phantom records that are only accessible during unit testing, leave this checkbox uncheck. You may need to add the Automatically_Share__c field to the Page Layout of the Custom Metadata Type.

2. Add the DisplaySharedFilesInRecordPage Lightning Component to the Lightning Record Page of the SObject that will contain attachments that you wish to share. 

3. Upload an attachment to the record of the type of the SObject that was entered in the Shared_Files_Setting__mdt custom metadata record.
4. Click Refresh in the Lightning Component 
![screenshot](/lightning-component.png)
5. Click View in the Link Column to See the Publicly Available URL 
6. To display these records in a Salesforce Site, query the records with the following information: 
    1. RelatedRecordId__c -> the Id of the linkedEntity of the attachment (parent record) 
    2. File_Name__c -> name of the file
    3. Filey_Type__c -> type of file
    4. Description__c -> the description of the file
    5. Download_Link__c -> the url that can be used to see the file
    6. Display_In_Public_Site__c -> if the file is currently shared or not

Security
--------
1. Shared_File__c records will not be created if the Logged In User does not have edit access to the Related Record. 
2. Shared_File__c records will throw an error if updated by a user that does not have edit access to the Related Record. 
3. The Lightning Component will disable the ‘Update Description’ and the input fields if the User does not have edit access to the Related Record. 

Credits
-------

As mentioned above, this app uses some classes from https://github.com/DouglasCAyers/sfdc-convert-attachments-to-chatter-files from Douglas C Ayers to convert Attachments to Salesforce Files, which simplifies the Unit Testing


