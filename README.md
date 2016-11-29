Automatically Share (publicly) Salesforce Files in Lightning Experience
====================================

This application can be used to automatically share (publicly) Salesforce Files in Lightning Experience. It makes the file publicly accessible through a URL and uses a lightning component to manage the sharing of the file.

How it works
------------

1. A Shared_Files_Setting__mdt metadata type is used to indicate what attachments should be publicly shared. It contains an SObjectName__c field that is used to indicate the name of the SObjects that have attachments that need to be shared. For instance, a Shared_Files_Setting__mdt record with the SObjectName__C of 'Contact' means that all attachments for contacts should be publicly shared.
2. For each attachment that should be shared, the app creates a Shared_File__c record. The Shared_File__c record contants the record Id of the related record (stored in the RelatedRecordId__c) and a checkbox called Shared_In_Public_Site__c which indicates if the file should be shared or not. 
3. The Shared_Files_Setting__mdt custom metadata record has a Automatically_Share__c checkbox field that defines the value of the Shared_In_Public_Site__c field of the Shared_File__c record on creation. The user has the option to change the value of the Shared_In_Public_Site__c setting using the Shared column of the Linghtning Component. 
3. When the Shared_File__c records are created or updated, a trigger checks if the Shared_In_Public_Site__c is set to true and if so it creates a ContentDistribution and copies the URL to the Download_Link__c field of the Shared_File__c record.
4. A Lightning Component is used to update these settings, remove sharing, update descriptions, etc. 

Dependencies
------------

1. The application uses some classes from https://github.com/DouglasCAyers/sfdc-convert-attachments-to-chatter-files from Douglas C Ayers to convert Attachments to Salesforce Files, which simplifies the Unit Testing. These classes requires Enhanced Notes enabled in the Salesforce Org. 
2. MyDomain is enabled for the Org.


Installation
-------------
1. Confirm Enhanced Notes are enabled, Lightning Experience is enabled and MyDomain has been deployed. 
2. Deploy from github. 
3. Allow read/write access to all fields in the Shared_File__c custom object for the profile of the users that will be sharing the Salesforce files.

Configuration
-------------
1. Create a Shared_Files_Setting__mdt record for each SObject that will contain attachments that you wish to share. In the ObjectName__c enter the SObject Name, such as ‘Account’ or ‘Project__c’. If you want these files to be shared automatically when the attachment is uploaded, check the Automatically_Share__c checkbox. The Used_For_Testing_Only__c checkbox is used to create phantom records that are only accessible during unit testing, leave this checkbox uncheck. You may need to add the Automatically_Share__c field to the Page Layout of the Custom Metadata Type.

2. Add the DisplaySharedFilesInRecordPage Lightning Component to the Lightning Record Page of the SObject that will contain attachments that you wish to share. 

3. Upload an attachment to the record of the type of the SObject that was entered in the Shared_Files_Setting__mdt custom metadata record.
4. Click Refresh in the Lightning Component 
![screenshot](/component-image.jpg)
5. Click View in the Link Column to See the Publicly Available URL 
6. To display these records in a Salesforce Site, query the Shared_File__c records with the following information: 
    1. RelatedRecordId__c -> the Id of the related record (linkedEntity) of the file (parent record) 
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

As mentioned above, this app uses the following classes from https://github.com/DouglasCAyers/sfdc-convert-attachments-to-chatter-files from Douglas C Ayers: ConvertAttachmentsToFilesEmailService, ConvertAttachmentsToFilesOptions, ConvertAttachmentsToFilesService, ConvertAttachmentsToFilesServiceTest. These classes are used to convert Attachments to Salesforce Files during Unit Testing. 


