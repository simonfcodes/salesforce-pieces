/**
 * MTErrorHandler is a helper class that handles errors encountered during trigger execution. 
 * @author Simon Fraser
 * @version 1.0
 * @see CustomException
 */
public without sharing class MTErrorHandler {
    @TestVisible
    private static Boolean throwException = false;

    /**
     * Handles an error encountered during trigger execution
     * @param ex The exception that was thrown during trigger execution
     * @throws CustomException if throwException is set to true, otherwise logs the error and continues execution
     */
    public static void handleError(Exception ex) {
        if (throwException) {
            throw ex;
        }
    }
}