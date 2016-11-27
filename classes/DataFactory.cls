public class DataFactory {
    
    public static List<Account> createVendors(Integer pNumber)
    {
        Id vendorRecordTypeId = ANM_Utils.getRecordTypeId('Account', 'Vendor'); 
        List<Account> vendorsToCreate = new List<Account>(); 
        for(Integer i = 0; i < pNumber; i++)
        {
            Account vendor = new Account(); 
            vendor.Name = 'Vendor '+i;
            if(vendorRecordTypeId != null) vendor.put('RecordTypeId', vendorRecordTypeId);
            //vendor.Vendor_Id__c = 'V0000'+i;
            vendorsToCreate.add(vendor);
        }
        if(!vendorsToCreate.isEmpty()) insert vendorsToCreate;
        return vendorsToCreate;
    }
    
    public static List<Account> createDepartments(Integer pNumber)
    {
        Id deptRecordTypeId = ANM_Utils.getRecordTypeId('Account', 'Department'); 
        List<Account> departmentsToCreate = new List<Account>(); 
        for(Integer i = 0; i < pNumber; i++)
        {
            Account department = new Account(); 
            department.Name = 'Department '+i;
            if(deptRecordTypeId != null) department.put('RecordTypeId', deptRecordTypeId);
            //department.Department_Code__c = 'DE'+i;
            departmentsToCreate.add(department);
        }
        if(!departmentsToCreate.isEmpty()) insert departmentsToCreate;
        return departmentsToCreate;
    }
    
    public static List<Contact> createContacts(Integer pNumber, Id pAccountId)
    {
        List<Contact> contactsToCreate = new List<Contact>(); 
        for(Integer i = 0; i < pNumber; i++)
        {
            Contact theContact = new Contact(); 
            theContact.FirstName = 'Department '+i;
            theContact.LastName = 'Department '+i;
            theContact.AccountId = pAccountId;
            contactsToCreate.add(theContact);
        }
        if(!contactsToCreate.isEmpty()) insert contactsToCreate;
        return contactsToCreate;
    }
    
    public static void createFiles(Integer pNumber, Set<Id> pParentIds)
    {
        if(pParentIds == null || pParentIds.isEmpty()) return; 
        
        List<Attachment> attachmentsToCreate = new List<Attachment>(); 
        
        for(Id parentId: pParentIds)
        {
            for(Integer i = 0; i < pNumber; i++)
            {
                Attachment newAttachment = new Attachment();
        	    newAttachment.Name = 'Unit Test Attachment '+i;
        	    newAttachment.Body = Blob.valueOf('Unit Test Attachment Body '+i);
        	    newAttachment.Description = 'The Description '+i;
        	    newAttachment.ParentId = parentId;
        	    newAttachment.isPrivate = false;
                attachmentsToCreate.add(newAttachment);
            }
        }
        
        if(!attachmentsToCreate.isEmpty())
        {
            insert attachmentsToCreate;
            List<Attachment> attachments = [SELECT Id, Name, Body, OwnerId, ParentId, isPrivate, Description FROM Attachment];
            System.debug(attachments);
            ConvertAttachmentsToFilesService serv = new ConvertAttachmentsToFilesService(); 
            serv.convert(attachments);
        }
    }
    
    
}