package com.ericsson.oss.cms.test.legacy.operators;

import java.io.IOException;

public interface LegacyOperator {

    /**
     * Method to copy and install the Perl test suite onto the remote OSS server.
     *
     * @throws IOException
     *         If things go wrong.
     */
    void installTestSuite() throws IOException;

    /**
     * Method that takes the STDOUT of a test case and returns the contents of the log file for that testcase.
     *
     * @param stdout
     *        STDOUT of a testcase execution.
     * @return The full contents of the testcase log.
     */
    String getTestOutput(final String stdout);

    /**
     * Method to parse the Testcase description from the test log contents.
     *
     * @param testCaseId
     *        The ID of the testcase.
     * @param logOutput
     *        The contents of the log file.
     * @return The testcase description.
     */
    String getTestCaseDescription(final String testCaseId, final String logOutput);

    /**
     * Method to remove the Perl test suite from the remote OSS server.
     */
    void deleteTestSuite();

    /**
     * Method that runs a testcase in tsch shell and returns the STDOUT which contains the path of the log file.
     *
     * @param testFile
     *        The name of the perl file to be executed
     * @param testCaseId
     *        The id of the test case to be executed
     * @return The full contents of shell output.
     */
    String executeTest(final String testFile, final String testCaseId);

}