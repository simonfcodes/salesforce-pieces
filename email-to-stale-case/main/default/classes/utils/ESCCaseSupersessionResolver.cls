/**
 * ESCCaseSupersessionResolver
 * 
 * PURPOSE
 *   Walk a chain of case supersessions (A -> B -> C) to find the most recent 'leaf' case in the chain (C).
 *   Decide what to do with an inbound EmailMessage that targeted the starting case: 
 *   -- REUSE  : the leaf is open             -> keep email on the leaf
 *   -- REOPEN : leaf is closed but recently  -> reopen leaf, keep email on the leaf case
 *   -- SPLIT  : leaf closed, too old (stale) -> create a new case, stitch leaf->new case
 * 
 * WHY THIS SHAPE (frontier/cursor/cache)
 *   We may need to resolve multiple starts in the same batch. To stay governor-safe: 
 *     - Keep a "cursor" per starting case, pointing at the current node/leaf
 *     - Advance all starts in lockstep 
 *     - Batch-load next hops, no SOQL in tight loops
 * 
 * KEY DATA STRUCTURES
 *   cursor          : Map<startCaseId, currentCaseId> 
 *                     For the chain that started at startCaseId, where are we now in the chain?
 *   frontier:       : Set<startCaseId>
 *                     Which START chains need another hop in this iteration? 
 *                     (Important: frontier tracks START case IDs, not node IDs)
 * 
 *   cache:          : Map<caseId, Case>
 *                     Every case we've loaded so far (so a node is only fetched once) 
 * 
 *   hops:           : Map<startCaseId, Integer>
 *                     Safety counter so we can cap traversal with maxHops (to avoid infinite loops in case of data corruption)
 * 
 * WHY nextFrontier.add(startCaseId) INSTEAD OF adding the next node to the frontier? 
 *   We always anchor work to the original start case (the one that the inbound email tried to hit).
 *   The "current node" (where we've chained to already) is stored in cursor[startCaseId]. 
 *   This means we update the cursor to the next case (B, C, ...) and put the startCaseId (A) back into the frontier
 *   to keep walking to the next iteration. This preserves the mapping: 
 *     DECISION is keyed by START case (what the email targeted)
 * 
 * WORKED EXAMPLE
 *   Chain: A -> B -> C -(leaf)
 *   t0 : cursor {A->A}, frontier {A}, cache {A}, hops {A->0}
 *   t1 : fetch B: cursor {A->B}, frontier {A}, cache {A, B}, hops {A->1}
 *   t2 : fetch C: cursor {A->C}, frontier {A}, cache {A, B, C}, hops {A->2}
 *   t3 : no next hop: leaf = C; decide based on C's status (reuse/reopen/split) for starting case A. 
 * 
 * MULTI-START EXAMPLE
 *   If emails target A and X simultaneously, frontier holds {A, X}
 *   Each iteration we gather ALL next hops across starts, pull them into a single SOQL, 
 *   advance both cursors, and repeat until all are done
 * 
 * CYCLE / HOP LIMIT
 *   If someone hand-edits Superseded_By_Case__c into a loop, or you see an absurd chain,
 *   maxHops cuts it off and treats the current node as leaf. 
 * 
 * USAGE
 *   Map<Id, Decision> d = ESCCaseSupersessionResolver.resolve(
 *       startIds, cutoffDatetime, 10);
 * 
 * DECISION SUBCLASS
 *   The decision subclass is a simple data structure that holds the start case Id, the leaf case Id, 
 *   and what to do with the leaf (reuse/reopen/split). It is returned in a map keyed by the start case Id. 
 * 
 * INTEGRATION TIPS
 *   - When SPLIT: after you insert the new case, set leaf.Superseded_By_Case__c = newCase.Id
 *     and reparent the in-flight EmailMessage to newCase.Id (must be done BEFORE INSERT)
 *     Emails cannot be reparented once they have been committed to the database. 
 *   - When REOPEN: update leaf.Status to your open status (and optionally run assignment rules)
 *   - When REUSE: just set em.ParentId = leafCaseId and let the email insert continue. 
 * @author Simon Fraser
 * @version 1.0.0
 */

public without sharing class ESCCaseSupersessionResolver {
    
    /**
     * Enum for the three possible decisions for an inbound email 
     * that targeted a particular case record
     */
    public enum DecisionType {
        REUSE, REOPEN, SPLIT
    }

    /**
     * Class representing a decision for an inbound email that targeted a particular case record
     */
    public class Decision {
        public Id startCaseId;             // case that the inbound email targeted
        public Id leafCaseId;              // the most recent case in the supersession chain
        public DecisionType decision;      // what to do with the leaf case (reuse/reopen/split)        
    }

    /** 
     * Resolve actions for a set of starting cases
     * @param startCaseIds          The cases the inbound emails targeted
     * @param cutoff                The datetime cutoff for considering a leaf case as stale (for reopening)
     *                              For example now().addDays(-14)
     * @param maxHops               The maximum number of hops to traverse in the supersession chain 
     *                              (to avoid infinite loops)
     * @return Map<Id, Decision>    A map from startId -> decision (leaf + action flag)
     */
    public static Map<Id, Decision> resolve(
        Set<Id> startCaseIds,
        Datetime cutoff,
        Integer maxHops
    ) {
        Map<Id, Decision> output = new Map<Id, Decision>();
        if (startCaseIds == null || startCaseIds.isEmpty()) { return output; } // nothing to do

        // Load initial cases into a cache
        Map<Id, Case> cache = ESCCaseService.loadCases(startCaseIds);

        // Initialize frontier and hops
        Set<Id> frontier = new Set<Id>(startCaseIds);
        Map<Id, Integer> hops = new Map<Id, Integer>();
        for (Id id : startCaseIds) { hops.put(id, 0); } // initialize hop count for each start case

        // Initialize cursor to point each starting case to itself (the first node in the chain)
        Map<Id, Id> cursor = new Map<Id, Id>();
        for (Id id : startCaseIds) { cursor.put(id, id); }

        while (!frontier.isEmpty()) {
            // Gather the next hop ids not yet in the cache

            Set<Id> toFetch = new Set<Id>();
            for (Id startId : frontier) {
                Case currentNode = cache.get(cursor.get(startId));
                if (currentNode == null) { continue; } // shouldn't happen, but guard against null
                // If the current node has a superseding case and we haven't exceeded max hops, 
                // add it to the list of cases to fetch in the next iteration
                if (currentNode.Superseded_By_Case__c != null && hops.get(startId) < maxHops) {
                    if (!cache.containsKey(currentNode.Superseded_By_Case__c)) {
                        toFetch.add(currentNode.Superseded_By_Case__c);
                    }
                }
            }

            // Load the next hop cases into the cache
            if (!toFetch.isEmpty()) {
                for (Case c : [SELECT Id, IsClosed, ClosedDate, Superseded_By_Case__c FROM Case WHERE Id IN :toFetch]) {
                    cache.put(c.Id, c);
                }
            }

            // Advance cursors and frontier or finish decisions
            Set<Id> nextFrontier = new Set<Id>();
            for (Id startId : frontier) {
                Id cur = cursor.get(startId);
                Case c = cache.get(cur);
                if (c == null) { continue; } // shouldn't happen, but guard against null

                Boolean canHop = (c.Superseded_By_Case__c != null && hops.get(startId) < maxHops);
                if (canHop) {
                    // advance the cursor to the next case in the chain
                    cursor.put(startId, c.Superseded_By_Case__c);
                    hops.put(startId, hops.get(startId) + 1);
                    nextFrontier.add(startId); // keep this start in the frontier for the next iteration
                } else {
                    // We've reached the leaf case for this start case or exceeded hops
                    // Make a decision based on the leaf case's status and closed date
                    Decision d = new Decision();
                    d.startCaseId = startId;
                    d.leafCaseId = cur;

                    if (!c.IsClosed) {
                        d.decision = DecisionType.REUSE;                        
                    } else if (c.ClosedDate != null && c.closedDate >= cutoff) {
                        d.decision = DecisionType.REOPEN;                        
                    } else {
                        d.decision = DecisionType.SPLIT;
                    }
                    output.put(startId, d);
                }
            }
            frontier = nextFrontier; // move to the next iteration with the updated frontier
        }
        return output;
    }
}