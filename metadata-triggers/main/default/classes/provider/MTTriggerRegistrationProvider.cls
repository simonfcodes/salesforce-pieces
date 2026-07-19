/**
 * Manages the retrieval of trigger registrations from the database.
 * For testing, allows for overriding the registrations for a given sobject and context.
 * @author Simon Fraser
 * @version 1.0
 * @see MTTriggerService
 */
public with sharing class MTTriggerRegistrationProvider {
    /**
     * Stores the test overrides by context key to a 
     * list of in-memory Trigger_Registration__mdt records.
     */
    @TestVisible
    private static Map<String, List<Trigger_Registration__mdt>> testOverride;

    /**
     * Generates a key for the test override map to pull the correct registrations. 
     * @param sobjectName The name of the sobject to retrieve registrations for.
     * @param context The context to retrieve registrations for.
     * @return A string key format: '<SObjectName:<Context>' e.g. 'Account:BEFORE_INSERT'
     */ 
    private static String key(String sobjectName, String context) {
        return sobjectName + ':' + context;
    }

    /**
     * Used by tests to override the registrations for a given sobject and context.
     * @param overrides A map of context keys to lists of Trigger_Registration__mdt in-memory records.
     */
    public static void setTestOverride(
        Map<String, List<Trigger_Registration__mdt>> overrides
    ) {
        testOverride = overrides;
    }

    /**
     * Retrieves the registrations for a given sobject and context.
     * @param sobjectName The name of the sobject to retrieve registrations for.
     * @param context The context to retrieve registrations for.
     * @return A list of CB_Trigger_Registration__mdt records.
     */
    public static List<Trigger_Registration__mdt> getRegistrations(
        String sobjectName,
        String context
    ) {
        if (Test.isRunningTest() && testOverride != null) {
            List<Trigger_Registration__mdt> fromOverride = testOverride.get(key(sobjectName, context));
            return fromOverride == null ? new List<Trigger_Registration__mdt>() : fromOverride;
        }

        return [
            SELECT Id, HandlerClass__c, ExecutionOrder__c, IsActive__c,
                SObject__c, Context__c, Project__c, ErrorMode__c
            FROM Trigger_Registration__mdt
            WHERE SObject__c = :sobjectName
              AND Context__c = :context
              AND IsActive__c = true
            ORDER BY ExecutionOrder__c ASC
        ];
    }
}