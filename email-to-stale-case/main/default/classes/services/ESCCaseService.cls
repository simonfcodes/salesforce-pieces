/**
 * Service class for loading case records related to EmailMessages. 
 * This service is part of the Email to Stale Case (ESC) feature.
 * Operates without sharing to ensure access to all necessary records.
 * @author Simon Fraser
 * @version 1.0.0
 */
public without sharing class ESCCaseService {
    
    /**
     * Convenience method to load starting cases by their IDs
     * @param startCaseIds the list of case IDs to load
     * @return a map of start cases to their corresponding IDs
     */
    public static Map<Id, Case> loadStartCases(List<Id> startCaseIds) {
        return loadCases(startCaseIds);
    }

    /** 
     * Load leaf cases by their IDs
     * @param startCasesByStartCaseId a map of starting cases to their corresponding IDs
     * @param decisionsByStartCaseId a map of superseding decisions by start case ID
     * @return a map of leaf cases by their corresponding Ids
     */
    public static Map<Id, Case> loadLeafCases(
        Map<Id, Case> startCasesByStartCaseId,
        Map<Id, ESCCaseSupersessionResolver.Decision> decisionsByStartCaseId
    ) {
        Set<Id> leafCaseIds = new Set<Id>();
        for (ESCCaseSupersessionResolver.Decision d : decisionsByStartCaseId.values()) {
            if (d == null || d.leafCaseId == null) { continue; } // skip null decisions or null leaf case ids
            leafCaseIds.add(d.leafCaseId);
        }

        Map<Id, Case> leafCasesById = new Map<Id, Case>();
        for (Id startId : startCasesByStartCaseId.keySet()) {
            if (leafIds.contains(startId)) {
                leafCases.put(startId, startCasesByStartCaseId.get(startId)); // the start case is also the leaf case
            }
        }

        Set<Id> leafCasesToFetch = new Set<Id>(leafCaseIds);
        leafCasesToFetch.removeAll(leafCasesById.keySet()); 
        if (!leafCasesToFetch.isEmpty()) {
            Map<Id, Case> fetchedLeafCases = loadCases(leafCasesToFetch);
            leafCasesById.putAll(fetchedLeafCases);
        }
        return leafCasesById;
    }

    /**
     * SOQL query to load cases by their id from a list of case IDs. 
     * @param caseIds the list of case IDs to load
     * @return a map of cases to their corresponding IDs
     */
    public static Map<Id, Case> loadCases(List<Id> caseIds) {
        if (!Schema.sObjectType.Case.isAccessible()) { return new Map<Id, Case>(); } // No access to Case object so return empty map
        Map<Id, Case> casesById = new Map<Id, Case>([
            SELECT Id, Subject, Status, OwnerId, AccountId, ContactId, 
                Origin, CreatedDate, IsClosed, CaseNumber, RecordTypeId, 
                ClosedDate, Superseded_By_Case__c
            FROM Case WHERE Id IN :caseIds 
        ]);
        return casesById;
    }

    /**
     * Convenience method to load cases from a set of case IDs.
     * @param caseIds the set of case IDs to load
     * @return a map of cases to their corresponding IDs
     */
    public static Map<Id, Case> loadCases(Set<Id> caseIds) {
        return loadCases(new List<Id>(caseIds));
    }
    
}