/**
 * CustomException
 * Extends the base exception class with a fluent, builder-style exception class
 * that captures structured metadata (error codes, source, record IDs, context) 
 * to enhance error handling and debugging in Salesforce. 
 */
public virtual class CustomException extends Exception implements System.Callable {

    // An optional error code to categorize the exception
    public String errorCode { get; private set; }

    // An optional source identifier to indicate where the exception originated. Usually a project name. 
    public String source { get; private set; }

    // A record ID associated with the exception, if applicable. This can be used to link the exception to a specific Salesforce record.
    public Id recordId { get; private set; }

    // The original exception that caused this exception to tbe thrown, if applicable. This allows for exception chaining and better debugging.
    public Exception original { get; private set; }

    // A map to hold additional context information related to the exception. 
    // This can include any relevant data in JSON serializable format, such as user IDs, timestamps, 
    // or other metadata that can aid in debugging and error analysis.
    public Map<String, Object> context { get; private set; }
    

    /**
     * Ensures that the context map is initialized. If the context map is null, it initializes it to an empty map.
     * This method is called before adding any context information to ensure that the context map is always
     */
    private void ensureInit() {
        if (this.context == null) { this.context = new Map<String, Object>(); }
    }

    /**
     * Sets the error code for the exception and returns the current instance for method chaining.
     * @param errorCode The error code to set.
     * @return The current instance of CustomException for method chaining.
     */
    public CustomException withErrorCode(String errorCode) {
        this.errorCode = errorCode;
        ensureInit();
        return this;
    }

    /**
     * Sets the source for the exception and returns the current instance for method chaining.
     * @param source The source to set.
     * @return The current instance of CustomException for method chaining.
     */
    public CustomException withSource(String source) {
        this.source = source; 
        ensureInit();
        return this;
    }

    /**
     * Sets the record ID for the exception and returns the current instance for method chaining.
     * @param recordId The record ID to set.
     * @return The current instance of CustomException for method chaining.
     */
    public CustomException withRecordId(Id recordId) {
        this.recordId = recordId;
        ensureInit();
        context.put('recordId', recordId);
        return this;
    }

    /**
     * Sets the original exception for the exception and returns the current instance for method chaining.
     * @param original The original exception to set.
     * @return The current instance of CustomException for method chaining.
     */
    public CustomException withOriginal(Exception original) {
        this.original = original;
        ensureInit();
        return this;        
    }

    /**
     * Adds a key-value pair to the context map and returns the current instance for method chaining.
     * If the key is 'recordId' (case-insensitive) and the value is an instance of Id, it also sets the recordId property.
     * @param key The key for the context entry.
     * @param value The value for the context entry.
     * @return The current instance of CustomException for method chaining.
     */
    public CustomException withContext(String key, Object value) {
        ensureInit();
        this.context.put(key, value);
        if (key != null && key.toLowerCase().equals('recordid') && value instanceof Id && this.recordId == null) {
            this.recordId = (Id) value;
        }
        return this;
    }

    /**
     * Creates a new instance of CustomException with the specified source, error code, and message.
     * @param source the source of the exception, usually a project name or module.
     * @param errorCode the error code categorizing the exception.
     * @param message the message describing the exception.
     * @return a new instance of CustomException with the specified properties.
     */
    public static CustomException of(String source, String errorCode, String message) {
        return new CustomException(message).withSource(source).withErrorCode(errorCode);
    }

    /**
     * Creates a new instance of CustomException with the specified source, error code, message, and original exception.
     * @param source the source of the exception, usually a project name or module.
     * @param errorCode the error code categorizing the exception.
     * @param message the message describing the exception.
     * @param original the original exception to wrap.
     * @return a new instance of CustomException with the specified properties.
     */
    public static CustomException wrap(String source, String errorCode, String message, Exception original) {
        return new CustomException(message).withSource(source).withErrorCode(errorCode).withOriginal(original);
    }

    /**
     * Describes the exception in a structured format, returning a map containing the type, source, error code, message, record ID, context, stack trace, and original exception details (if any).
     * @return A map containing the structured description of the exception.
     */
    public virtual Map<String, Object> describe() {
        ensureInit();
        Map<String, Object> describeMap = new Map<String, Object>();
        describeMap.put('type', getTypeName());
        describeMap.put('source', source);
        describeMap.put('errorCode', errorCode);
        describeMap.put('message', getMessage());
        describeMap.put('recordId', recordId);
        describeMap.put('context', context);
        describeMap.put('stack', getStackTraceString());
        if (original != null) {
            describeMap.put('original', new Map<String, Object>{
                'type' => original.getTypeName(),
                'message' => original.getMessage(),
                'stack' => original.getStackTraceString()
            });
        }
        return describeMap;
    }

    /**
     * Converts the exception to a log-friendly string representation.
     * @return A string suitable for logging.
     */
    public virtual String toLogString() {
        return toJson();
    }

    /**
     * Converts the exception to a JSON string representation.
     * @return A JSON string representing the exception.
     */
    public virtual String toJson() {
        return JSON.serialize(describe());
    }   

    /**
     * Implements the System.Callable interface to allow dynamic method invocation on the exception instance.
     * @param action The action to perform (e.g., 'describe', 'toLogString', 'toJson').
     * @param args A map of arguments for the action (not used in this implementation).
     * @return The result of the invoked action, or null if the action is not recognized.
     */
    public Object call(String action, Map<String, Object> args) {
        if (String.isBlank(action)) { return null; }
        String a = action.trim().toLowerCase();
        if (a == 'describe') { return describe(); }
        if (a == 'tologstring') { return toLogString(); }
        if (a == 'tojson') { return toJson(); }
        return null;
    }
}