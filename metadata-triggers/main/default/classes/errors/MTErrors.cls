/**
 * MTErrors is a factory class for creating error exceptions relating to metadata trigger execution.
 * It uses the CustomException class to create exceptions. There is a dependency on CustomException.
 * @author Simon Fraser
 * @version 1.0
 * @see CustomException
 */
public without sharing class MTErrors {
    public static final String SRC = 'metadata-triggers';

    /**
     * Creates a new CustomException for a handler class not found. 
     * This error is thrown when a handler class specified in the Trigger_Registration__mdt record is not found.
     * @param className The name of the handler class that was not found.
     * @param reg The Trigger_Registration__mdt record that specified the handler class.
     * @return A new CustomException 
     */
    public static CustomException handlerClassNotFound(String className, Trigger_Registration__mdt reg) {
        return CustomException.of(SRC, 'HANDLER_CLASS_NOT_FOUND', 'No handler class found with the specified class name: ' + className)
            .withContext('className', className)
            .withContext('triggerContext', reg.Context__c)
            .withContext('sobjectName', reg.SObject__c)
            .withContext('project', reg.Project__c);
    }

    /** 
     * Creates a new CustomException for an invalid handler class.
     * This error is thrown when a handler class is specified by the metadata record but is not an instance of the MTTriggerHandler class.
     * @param className The name of the handler class that is invalid.
     * @param reg The Trigger_Registration__mdt record that specified the handler class.
     * @return A new CustomException
     */
    public static CustomException invalidHandlerClass(String className, Trigger_Registration__mdt reg) {
        return CustomException.of(SRC, 'INVALID_HANDLER_CLASS', 'The specified handler class is not an instance of MTTriggerHandler: ' + className)
            .withContext('className', className)
            .withContext('triggerContext', reg.Context__c)
            .withContext('sobjectName', reg.SObject__c)
            .withContext('project', reg.Project__c);
    }

    /**
     * Creates a new CustomException for a handler class not specified.
     * This error is thrown when a handler class is not specified by the metadata record.
     * This is a programming error and should be caught and handled by the developer.
     * The default configuration is that a handler class is required by the metadata object. 
     * @param reg The metadata record for the trigger registration.
     * @return A new CustomException for a handler class not specified.
     */
    public static CustomException unspecifiedHandler(Trigger_Registration__mdt reg) {
        return CustomException.of(SRC, 'UNSPECIFIED_HANDLER', 'No handler class specified for registration: ' + reg.Id)
            .withContext('triggerContext', reg.Context__c)
            .withContext('sobjectName', reg.SObject__c)
            .withContext('project', reg.Project__c);
    }
    
    /** 
     * Creates a new CustomException for no sample object found. 
     * This error is thrown when a sample object is not found for the fired trigger.
     * This should not happen. But just in case.
     * @return A new CustomException for no sample object found. 
     */
    public static CustomException noSampleObjectFound() {
        return CustomException.of(SRC, 'NO_SAMPLE_OBJECT_FOUND', 'No sample object found for the fired trigger');
    }

    /**
     * Creates a new CustomException for an unrecognized trigger context.
     * This error is thrown when the trigger context is not recognized by the trigger service.
     * This should not happen. But just in case Salesforce adds a new type. 
     * @return A new CustomException for an unrecognized trigger context.
     */
    public static CustomException unrecognizedTriggerContext() {
        return CustomException.of(SRC, 'UNRECOGNIZED_TRIGGER_CONTEXT', 'Unrecognized trigger context');        
    }

    /**
     * Creates a new CustomException for a maximum loop count reached.
     * This error is thrown when the loop count is greater than the maximum loop count specified by the handler.
     * @param handler The handler that has reached the maximum loop count.
     * @param max The maximum loop count specified by the handler.
     * @return A new CustomException for a maximum loop count reached.
     * @see MTTriggerHandler#getMaxLoopCount()
     */
    public static CustomException maxLoopCountReached(String handler, Integer max) {
        return CustomException.of(SRC, 'MAX_LOOP_COUNT_REACHED', 'Maximum loop count of ' + String.valueOf(max) + ' reached for handler: ' + handler)
            .withContext('handler', handler)
            .withContext('maxLoopCount', max);
    }

    /**
     * Creates a new CustomException for a trigger handler called outside of trigger execution
     * This error is thrown when a trigger handler is called from outside of a trigger.
     * @return a new CustomException
     * @see MTTriggerHandler#run()
     */
    public static CustomException triggerHandlerCalledOutsideTrigger() {
        return CustomException.of(SRC, 'TRIGGER_HANDLER_CALLED_OUTSIDE_TRIGGER', 'Trigger handler called outside of trigger execution');
    }
}