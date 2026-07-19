/**
 * TriggerService is the core service class orchestrating trigger handler execution
 * This class is responsible for determining the current trigger context, 
 * querying the appropriate registrations,
 * and executing the handler classes in the correct order.
 * @author Simon Fraser
 * @version 1.0
 * @see MTTriggerRegistrationProvider
 */
public with sharing class MTTriggerService {
    
    /**
     * Runs the trigger service for the current trigger context.     
     * This method is called from the trigger context and will execute the appropriate handler classes.
     * It gets the SObjectName and context from the trigger and uses the TriggerRegistrationProvider to get the appropriate registrations.
     * Then it executes the handler classes {@link MTTriggerService#executeHandler(String)} in the correct order.
     * @see AccountTrigger
     */
    public static void run() {
        List<Trigger_Registration__mdt> regs = new List<Trigger_Registration__mdt>();
        try {
            // Determine the SObjectName and Context from the trigger context
            String sobjectName = getSObjectNameFromTrigger();
            String context = getContextKey();
            // Get each metadata trigger registation for the SObject and context
            regs = MTTriggerRegistrationProvider.getRegistrations(sobjectName, context);
        } catch (Exception ex) {
            // handle the error
            MTErrorHandler.handleError(ex);
        }

        // Execute each handler class in the correct order as retrieved
        for (Trigger_Registration__mdt reg : regs) {
            try { 
                executeHandler(reg.HandlerClass__c, reg);
            } catch (Exception ex) {
                if (reg.ErrorMode__c == 'FAIL_FAST') {
                    MTErrorHandler.handleError(ex);
                    break; // Don't continue firing triggers 
                }
                MTErrorHandler.handleError(ex);
                continue; // Continue to the next handler
            }
        }
    }

    /**
     * Executes a single handler class
     * @param className the fully qualified Apex class name of the handler to execute.
     * @param reg the custom trigger registration record 
     * @see MTTriggerRegistrationProvider#getRegistrations(String, String)
     */
    private static void executeHandler(String className, Trigger_Registration__mdt reg) {
        if (String.isBlank(className)) {
            throw MTErrors.unspecifiedHandler(reg);
        }

        Type t = Type.forName(className);
        if (t == null) {
            throw MTErrors.handlerClassNotFound(className, reg);
        }

        Object instance = t.newInstance();
        if (!(instance instanceof MTTriggerHandler)) {
            throw MTErrors.invalidHandlerClass(className, reg);
        }

        MTTriggerHandler h = (MTTriggerHandler) instance;
        h.run();
    }

    /**
     * Gets the context key from the current trigger context.
     * @return A string representing the current context
     */
    private static String getContextKey() {
        if (Trigger.isBefore) {
            if (Trigger.isInsert) { return 'BEFORE_INSERT'; }
            if (Trigger.isUpdate) { return 'BEFORE_UPDATE'; }
            if (Trigger.isDelete) { return 'BEFORE_DELETE'; }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) { return 'AFTER_INSERT'; }
            if (Trigger.isUpdate) { return 'AFTER_UPDATE'; }
            if (Trigger.isDelete) { return 'AFTER_DELETE'; }
            if (Trigger.isUndelete) { return 'AFTER_UNDELETE'; }
        }

        // If we reach here, the context is not recognized
        throw MTErrors.unrecognizedTriggerContext();
    }

    /** 
     * Gets the SObject name from the current trigger context.
     * @return A string representing the SObject name. 
     */
    private static String getSObjectNameFromTrigger() {
        SObject sample;
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            if (Trigger.new != null && !Trigger.new.isEmpty()) {
                sample = Trigger.new[0]; // Get the first record from Trigger.new
            }
        } else if (Trigger.isDelete) {
            if (Trigger.old != null && !Trigger.old.isEmpty()) {
                sample = Trigger.old[0]; // Get the first record from Trigger.old
            }
        }

        if (sample == null) {
            MTErrors.noSampleObjectFound();
        }

        return sample.getSObjectType().getDescribe().getName();
    }
}