public class DataFactory {
    
    public static List<Account> createAccounts(Integer pNumber)
    {
        List<Account> accountsToCreate = new List<Account>(); 
        for(Integer i = 0; i < pNumber; i++)
        {
            Account theAccount = new Account(); 
            theAccount.Name = 'Account '+i;
            accountsToCreate.add(theAccount);
        }
        if(!accountsToCreate.isEmpty()) insert accountsToCreate;
        return accountsToCreate;
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