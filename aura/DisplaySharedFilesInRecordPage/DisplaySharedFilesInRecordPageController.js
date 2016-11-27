({
     doInit : function(component, event, helper) {
         
          helper.getSharedFiles(component);
          helper.checkIfHasAccess(component);
          helper.hideSpinner(component); 
     }, 
    updateRecords : function(component, event, helper){
        helper.updateSharedFiles(component);
    },
    showSpinner : function (component, event, helper) {
        helper.showSpinner(component);   
    },
    hideSpinner : function (component, event, helper) {
        helper.hideSpinner(component);   
    }
})