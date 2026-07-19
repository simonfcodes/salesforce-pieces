@isTest
private class CustomExceptionTest {
    @isTest
    static void testOfAndDescribeCallable() {
        Id rid = UserInfo.getUserId();

        CustomException ex = CustomException.of('TA', 'TA.VAL.ASSIGNMENT.USER_REQUIRED', 'UserId is required')
            .withRecordId(rid).withContext('foo', 'bar');
        
        Assert.areEqual('TA', ex.source, 'Source should be TA');
        Assert.areEqual('TA.VAL.ASSIGNMENT.USER_REQUIRED', ex.errorCode, 'Error code should be TA.VAL.ASSIGNMENT.USER_REQUIRED');
        Assert.areEqual(rid, ex.recordId, 'Record ID should be ' + rid);
        
        Map<String, Object> d = ex.describe();
        Assert.areEqual('TA', d.get('source'), 'Source in describe should be TA');
        Assert.areEqual('TA.VAL.ASSIGNMENT.USER_REQUIRED', d.get('errorCode'), 'Error code in describe should be TA.VAL.ASSIGNMENT.USER_REQUIRED');
        Assert.areEqual(rid, d.get('recordId'), 'Record ID in describe should be ' + rid);
        Assert.isTrue(d.containsKey('stack'), 'Stack should be present');

        Object od = ex.call('describe', null);
        Assert.isTrue(od instanceof Map<String, Object>, 'Describe should return a map');

        Object jsonString = ex.call('tojson', null);
        Assert.isTrue(jsonString instanceof String, 'To JSON should return a string');
        Assert.isTrue(((String)jsonString).contains('errorCode'), 'JSON should contain errorCode');
    }

    @isTest
    static void testWrapOriginal() {
        Exception original;
        try {
            Integer x = 1/0;
        } catch (Exception e) {
            original = e;
        }

        CustomException ex = CustomException.wrap('TA', 'TA.SYS.UNEXPECTED', 'boom', original);
        Map<String, Object> d = ex.describe();
        Assert.isTrue(d.containsKey('original'), 'Original error should be present');
        Map<String, Object> originalMap = (Map<String, Object>) d.get('original');
        Assert.areEqual(original.getTypeName(), originalMap.get('type'), 'Original type should be ' + original.getTypeName());
    }

    @isTest
    static void testWithContextPromotesRecordId() {
        Id rid = UserInfo.getUserId();
        CustomException ex = CustomException.of('TA', 'X', 'msg').withContext('recordId', rid);

        Assert.areEqual(rid, ex.recordId, 'Record ID should be promoted to parent exception object from context');
    }
}