({
     getSharedFiles: function(component) {
        var action = component.get("c.returnRelatedSharedFiles");
        action.setParams({
          pRecordId: component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            // display the product to the chrome dev console (for fun)
            component.set("v.sharedFiles", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    updateSharedFiles: function(component){
        var action = component.get("c.updatedSharedFiles");
        action.setParams({
          sharedFiles: component.get("v.sharedFiles"),
          pRecordId: component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            // display the product to the chrome dev console (for fun)
            component.set("v.sharedFiles", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    checkIfHasAccess: function(component) {
        var action = component.get("c.hasEditAccess");
        action.setParams({
          pRecordId: component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            // display the product to the chrome dev console (for fun)
            component.set("v.hasAccess", a.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(component) {
        var cmpTarget = component.find('theTable');
        $A.util.addClass(cmpTarget, 'hideForSpinner');
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();
    },
    hideSpinner: function(component) {
        var cmpTarget = component.find('theTable');
        $A.util.removeClass(cmpTarget, 'hideForSpinner');
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        evt.fire();
    }
})