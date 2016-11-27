({
     doInit : function(component, event, helper) {
         var cmpTarget = component.find('theTable');
         $A.util.removeClass(cmpTarget, 'hideForSpinner');
          helper.getSharedFiles(component);
          helper.checkIfHasAccess(component);
          var spinner = component.find('spinner');
         var evt = spinner.get("e.toggle");
         evt.setParams({ isVisible : false });
         evt.fire();  
     }, 
    updateRecords : function(component, event, helper){
        helper.updateSharedFiles(component);
    },
    showSpinner : function (component, event, helper) {
        var cmpTarget = component.find('theTable');
         $A.util.addClass(cmpTarget, 'hideForSpinner');
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();    
    },
    hideSpinner : function (component, event, helper) {
        var cmpTarget = component.find('theTable');
         $A.util.removeClass(cmpTarget, 'hideForSpinner');
       var spinner = component.find('spinner');
       var evt = spinner.get("e.toggle");
       evt.setParams({ isVisible : false });
       evt.fire();    
    }
})