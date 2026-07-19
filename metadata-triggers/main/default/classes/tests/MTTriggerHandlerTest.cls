
@isTest
private class MTTriggerHandlerTest {
    
    private static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';
    
    private static String lastMethodCalled; 
    
    private static MTTriggerHandlerTest.TestHandler handler;
    
    static {
        handler = new MTTriggerHandlerTest.TestHandler();
        //override its internal trigger detection
        handler.isTriggerExecuting = true;
    }
    
    /*
    Unit tests
    */
    
    // context tests
    @isTest
    static void testBeforeInsert(){
        beforeInsertMode();
        handler.run();
        Assert.areEqual('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
    }
    
    @isTest
    static void testBeforeUpdate() {
        beforeUpdateMode();
        handler.run();
        Assert.areEqual('beforeUpdate', lastMethodCalled, 'last method should be beforeUpdate');
    }
    
    @isTest
    static void testBeforeDelete() {
        beforeDeleteMode();
        handler.run();
        Assert.areEqual('beforeDelete', lastMethodCalled, 'last method should be beforeDelete');
    }
    
    @isTest
    static void testAfterInsert() {
        afterInsertMode();
        handler.run();
        Assert.areEqual('afterInsert', lastMethodCalled, 'last method should be afterInsert');
        
    }
    @isTest
    static void testAfterUpdate() {
        afterUpdateMode();
        handler.run();
        Assert.areEqual('afterUpdate', lastMethodCalled, 'last method should be afterUpdate');
        
    }
    @isTest
    static void testAfterDelete() {
        afterDeleteMode();
        handler.run();
        Assert.areEqual('afterDelete', lastMethodCalled, 'last method should be afterDelete');
        
    }
    @isTest
    static void testAfterUndelete() {
        afterUndeleteMode();
        handler.run();
        Assert.areEqual('afterUndelete', lastMethodCalled, 'last method should be afterUndelete');
    }
    
    @isTest
    static void testNonTriggerContext() {
        try {
            handler.run();
            Assert.fail('the handler ran but should have thrown an exception');
        } catch(CustomException te){
            Assert.areEqual(TRIGGER_CONTEXT_ERROR, te.getMessage(), 'the exception message should match');
        } catch(Exception e) {
            Assert.fail('the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }
    }
    
    // test the bypass API
    
    @isTest
    static void testBypassAPI() {
        afterUpdateMode();
        
        MTTriggerHandler.bypass('TestHandler');
        handler.run();
        Assert.isNull(lastMethodCalled, 'last method should be null when bypassed');
        Assert.isTrue(MTTriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();
        
        // clear that bypass and run handler
        MTTriggerHandler.clearBypass('TestHandler');
        handler.run();
        Assert.areEqual('afterUpdate', lastMethodCalled, 'last method called should be afterUpdate');
        Assert.isFalse(MTTriggerHandler.isBypassed('TestHandler'), 'test handler should not be bypassed');
        resetTest();
        
        // test a re-bypass and run handler
        MTTriggerHandler.bypass('TestHandler');
        handler.run();
        Assert.isNull(lastMethodCalled, 'last method should be null when bypassed');
        Assert.isTrue(MTTriggerHandler.isBypassed('TestHandler'), 'test handler should be bypassed');
        resetTest();
        
        // clear all bypasses and run handler
        MTTriggerHandler.clearAllBypasses();
        handler.run();
        Assert.areEqual('afterUpdate', lastMethodCalled, 'last method called should be afterUpdate');
        Assert.isFalse(MTTriggerHandler.isBypassed('TestHandler'), 'test handler should not be bypassed');
        resetTest();
    }
    
    // instance method tests
    
    @isTest
    static void testLoopCount() {
        beforeInsertMode();
        handler.setMaxLoopCount(2);
        
        //run handler twice
        handler.run();
        handler.run();
        
        // clear the tests
        resetTest();
        
        try {
            // try running the handler. This should exceed the limit. 
            handler.run();
            Assert.fail('the handler should throw an exception on the 3rd run when maxloopcount is 3');
        } catch(CustomException te) {
            // we expect to be here
            Assert.isNull(lastMethodCalled, 'last method should be null');
        } catch(Exception e) {
            Assert.fail('the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }
        
        // clear the tests
        resetTest();
        
        // clear the loop count
        handler.clearMaxLoopCount();
        
        try {
            // re-run the handler. This should now run
            handler.run();
            Assert.areEqual('beforeInsert', lastMethodCalled, 'last method should be beforeInsert');
        } catch(CustomException te) {
            Assert.fail('running the handler after clearing the loop count should not throw an exception');
        } catch(Exception e) {
            Assert.fail('the exception thrown was not expected: ' + e.getTypeName() + ': ' + e.getMessage());
        }
    }
    
    @isTest
    static void testLoopCountClass() {
        MTTriggerHandler.LoopCount lc = new MTTriggerHandler.LoopCount();
        Assert.areEqual(5, lc.getMax(), 'max should be five on init');
        Assert.areEqual(0, lc.getCount(), 'count should be zero on init');
        
        lc.increment();
        Assert.areEqual(1, lc.getCount(), 'count should be 1');
        Assert.isFalse(lc.exceeded(), 'should not be exceeded with count of 1');
        
        lc.increment();
        lc.increment();
        lc.increment();
        lc.increment();
        Assert.areEqual(5, lc.getCount(), 'count should be 5');
        Assert.isFalse(lc.exceeded(), 'count should not be exceeded with count of 5');
        
        lc.increment();
        Assert.areEqual(6, lc.getCount(), 'count should be 6');
        Assert.isTrue(lc.exceeded(), 'should be exceeded with count of six');
    }
    
    // private method tests
    
    @isTest
    static void testGetHandlerName() {
        Assert.areEqual('TestHandler', handler.getHandlerName(), 'handler name should match class name');
    }
    
    // test virtual methods
    
    @isTest
    static void testVirtualMethods() {
        MTTriggerHandler h = new MTTriggerHandler();
        h.beforeInsert();
        h.beforeUpdate();
        h.beforeDelete();
        h.afterInsert();
        h.afterUpdate();
        h.afterDelete();
        h.afterUndelete();
    }
    
    // test utilities
    
    private static void resetTest() {
        lastMethodCalled = null;
    }
    
    // Testing modes
    
    private static void beforeInsertMode() {
        handler.setTriggerContext('before insert', true);
    }
    
    private static void beforeUpdateMode() {
        handler.setTriggerContext('before update', true);
    }
    
    private static void beforeDeleteMode() {
        handler.setTriggerContext('before delete', true);
    }
    
    private static void afterInsertMode() {
        handler.setTriggerContext('after insert', true);
    }
    
    private static void afterUpdateMode() {
        handler.setTriggerContext('after update', true);
    }
    
    private static void afterDeleteMode() {
        handler.setTriggerContext('after delete', true);
    }
    
    private static void afterUndeleteMode() {
        handler.setTriggerContext('after undelete', true);
    }
    
    // test implementation of the TriggerHandler
    
    private class TestHandler extends MTTriggerHandler {
        public override void beforeInsert() {
            MTTriggerHandlerTest.lastMethodCalled = 'beforeInsert';
        }
        
        public override void beforeUpdate() {
            MTTriggerHandlerTest.lastMethodCalled = 'beforeUpdate';
        }
        
        public override void beforeDelete() {
            MTTriggerHandlerTest.lastMethodCalled = 'beforeDelete';
        }
        
        public override void afterInsert() {
            MTTriggerHandlerTest.lastMethodCalled = 'afterInsert';
        }
        
        public override void afterUpdate() {
            MTTriggerHandlerTest.lastMethodCalled = 'afterUpdate';
        }
        
        public override void afterDelete() {
            MTTriggerHandlerTest.lastMethodCalled = 'afterDelete';
        }
        
        public override void afterUndelete() {
            MTTriggerHandlerTest.lastMethodCalled = 'afterUndelete';
        }
        
    }
}