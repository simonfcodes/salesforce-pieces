public without sharing class ESCEmailToCaseService {
    public class E2CConfig {
        public Id ownerId; 
        public Id recordTypeId;

        public E2CConfig() {
            ownerId = null;
            recordTypeId = null;
        }
    }

    @TestVisible private static Map<String, E2CConfig> cacheOverride;
    @TestVisible private static Map<String, E2CConfig> cache;

    @TestVisible
    static void setCacheOverride(Map<String, E2CConfig> overrides) {
        cacheOverride = overrides;
        cache = null; // clear the cache so it will be rebuilt with the overrides
    }

    @TestVisible
    static void clearCache() {
        cacheOverride = null;
        cache = null;
    }

    private static Map<String, E2CConfig> getCache() {
        Map<String, E2CConfig> result = new Map<String, E2CConfig>();

        
    }
}