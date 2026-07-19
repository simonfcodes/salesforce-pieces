/**
 * Metadata Triggers - Trigger Handler Class
 * This class is extended by individual trigger handlers where the actual trigger logic is implemented. 
 * Inherit this class from all other trigger handlers. 
 * @author Kevin O'Hara
 * @author Simon Fraser
 * @version 1.0
 * Documentation added by Simon Fraser
 * Original repository: https://github.com/kevinohara80/sfdc-trigger-framework
 */
public virtual class MTTriggerHandler {
    
    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;

    // whether the trigger is currently executing, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
    }

    /**
     * Public Constructor
     * Initializes the trigger context and sets isTriggerExecuting to true if a trigger is executing.
     */
    public MTTriggerHandler() {
        this.setTriggerContext();
    }

    /**
     * run() method is the main entry point for the trigger handler. 
     * It is run on a new instance of the class inheriting this Trigger Handler class. 
     */
    public void run() {
        if(!validateRun()) {
            return;
        }

        addToLoopCount();
        // If exception is thrown, it means that the handler is trying to execute more than the maximum set loops allowed and breaks here. 
        // Dispatch to the correct handler method
        switch on this.context {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            
            }
            when BEFORE_DELETE {
                this.beforeDelete();
                
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }

    /**
     * / API allows setting the maximum number of loops (times) an trigger handler should run.
     * @param max The maximum number of times the trigger handler should run.
     */ 
    public void setMaxLoopCount(Integer max){
        String handlerName = getHandlerName();
        if(!MTTriggerHandler.loopCountMap.containsKey(handlerName)) {
            MTTriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));            
        } else {
            MTTriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }
    /**
     * API allows clearing the maximum number of loops (times) an trigger handler should run.
     */
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

    /*
        Public Static Methods
    */

    /**
     * if a handler is set to be bypassed, then it doesn't run because validateRun() checks for bypassed handlers.
     * This can be useful to bypass triggers on data loads or tests where the trigger might interfere with the data load or test.
     * @param handlerName The Apex Class Name of the trigger handler to bypass.
     */
    public static void bypass(String handlerName){
        MTTriggerHandler.bypassedHandlers.add(handlerName);
    }
    /**
     * Clear bypasses for a trigger handler. You should always clear bypasses after a test or data load to avoid unexpected behavior in other tests or data loads.
     * @param handlerName The Apex Class Name of the trigger handler to clear bypasses for. 
     */
    public static void clearBypass(String handlerName) {
        MTTriggerHandler.bypassedHandlers.remove(handlerName);
    }

    /**
     * Check if a trigger handler is bypassed.
     * @param handlerName The Apex Class Name of the trigger handler to check.
     * @return Boolean indicating whether the trigger handler is bypassed.
     */
    public static Boolean isBypassed(String handlerName) {
        return MTTriggerHandler.bypassedHandlers.contains(handlerName);
    }
    
    /**
     * Clear all bypasses for all trigger handlers. 
     */
    public static void clearAllBypasses() {
        MTTriggerHandler.bypassedHandlers.clear();
    }

    /* 
        Private Instance Methods
    */

    /**
     * Sets trigger context with ctx as null. 
     */
    @TestVisible
    private void setTriggerContext() {
        // this calls setTriggerContext with ctx as null
        this.setTriggerContext(null, false);
    }

    /**
     * Sets trigger context based on the provided context string and test mode flag.
     * @param ctx The context string representing the trigger context (e.g., 'before insert', 'after update').
     * @param testMode A Boolean flag indicating whether the method is being called in test mode. 
     */
    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        // if testMode is TRUE, set isTriggerExecuting to TRUE so that the test methods will run. 
        // ctx and testMode are used together to execute trigger tests. 
        
        if(!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }
        // if a trigger is actually executing, the context is set by the first set of conditionals.
        // if in test mode, then the second set of conditionals are run, which set the context values based on ctx.
        if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) || (ctx != null && ctx == 'before insert')) {
            this.context = TriggerContext.BEFORE_INSERT;
        } else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) || (ctx != null && ctx == 'before update')) {
            this.context = TriggerContext.BEFORE_UPDATE; 
        } else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) || (ctx != null && ctx == 'before delete')) {
            this.context = TriggerContext.BEFORE_DELETE;
        } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) || (ctx != null && ctx == 'after insert')) {
            this.context = TriggerContext.AFTER_INSERT;
        } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) || (ctx != null && ctx == 'after update')) {
            this.context = TriggerContext.AFTER_UPDATE;
        }  else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) || (ctx != null && ctx == 'after delete')) {
            this.context = TriggerContext.AFTER_DELETE;
        } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) || (ctx != null && ctx == 'after undelete')) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    /**
     * Increments the loop count for the current trigger handler and checks if it exceeds the maximum allowed loops.
     * If the maximum is exceeded, an exception is thrown.
     */
    @TestVisible
    private void addToLoopCount() {        
        String handlerName = getHandlerName();
        // check if the loopCountMap has the handler name in, which means setMaxLoopCount was called.
        if(MTTriggerHandler.loopCountMap.containsKey(handlerName)){
            Boolean exceeded = MTTriggerHandler.loopCountMap.get(handlerName).increment();
            if (exceeded) {
                Integer max =  MTTriggerHandler.loopCountMap.get(handlerName).max;
                throw MTErrors.maxLoopCountReached(handlerName, max);
            }
        }
    }

    /**
     * Validates if the trigger should continue to run.
     * @return TRUE if the trigger should continue, FALSE otherwise.
     */
    @TestVisible
    private Boolean validateRun() {
        // this function is called by run(), should return TRUE to continue, FALSE to break 
        if (!this.isTriggerExecuting || this.context == null) {
            throw MTErrors.triggerHandlerCalledOutsideTrigger();
        }
        // if the bypassedHandlers set contains this trigger handler's name, return FALSE 
        // so that run() returns early . 
        return !MTTriggerHandler.bypassedHandlers.contains(getHandlerName());
    }

    /**
     * Retrieves the name of the current trigger handler.
     * @return The name of the trigger handler.
     */
    @TestVisible
    private String getHandlerName() {
        return this.toString().substringBefore(':');
    }

    /**
     * These methods are intended to be overridden in subclasses to implement specific logic for each trigger context.
     */

    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void beforeInsert(){}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void beforeUpdate(){}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void beforeDelete(){}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void afterInsert(){}    
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void afterUpdate(){}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void afterDelete(){}
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    protected virtual void afterUndelete(){}

    /* 
        Inner classes
    */

    // Loop Count - inner class handles the loop count maximums
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count; 

        /**
         * Default constructor initializes the maximum loop count to 5 and the current count to 0.
         */
        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        /**
         * Constructor initializes the maximum loop count to the specified value and the current count to 0.
         * @param max The maximum number of loops allowed.
         */

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        /**
         * Increments the current loop count and checks if it exceeds the maximum allowed loops.
         * @return TRUE if the current count exceeds the maximum, FALSE otherwise.
         */
        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        /**
         * Checks if the current loop count has exceeded the maximum allowed loops.
         * @return TRUE if the current count exceeds the maximum, FALSE otherwise.
         */
        public Boolean exceeded() {
            return this.max >= 0 && this.count > this.max;
        }

        /**
         * Retrieves the maximum allowed loop count.
         * @return The maximum loop count.
         */
        public Integer getMax() {
            return this.max;
        }
        
        /**
         * Retrieves the current loop count.
         * @return The current loop count.
         */
        public Integer getCount() {
            return this.count;
        }

        /**
         * Sets the maximum allowed loop count.
         * @param max The maximum loop count.
         */
        public void setMax(Integer max) {
            this.max = max;
        }
    }

    // Potential Trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE, AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, AFTER_UNDELETE
    }
}