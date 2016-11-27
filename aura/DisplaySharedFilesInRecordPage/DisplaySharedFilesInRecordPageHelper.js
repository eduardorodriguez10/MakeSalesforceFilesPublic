({
    
     getSharedFiles: function(component) {
        var action = component.get("c.returnRelatedSharedFiles");
        action.setParams({
          pRecordId: component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            // display the product to the chrome dev console (for fun)
            console.log(a.getReturnValue());
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
            console.log(a.getReturnValue());
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
            console.log(a.getReturnValue());
            component.set("v.hasAccess", a.getReturnValue());
        });
        $A.enqueueAction(action);
    }
})