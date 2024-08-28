package com.ericsson.oss.cms.test.legacy;

import static org.hamcrest.Matchers.containsString;

import java.io.IOException;

import org.testng.annotations.AfterSuite;
import org.testng.annotations.BeforeSuite;
import org.testng.annotations.Test;

import com.ericsson.cifwk.taf.TestCase;
import com.ericsson.cifwk.taf.TorTestCaseHelper;
import com.ericsson.cifwk.taf.annotations.Context;
import com.ericsson.cifwk.taf.annotations.DataDriven;
import com.ericsson.cifwk.taf.annotations.Input;
import com.ericsson.cifwk.taf.annotations.TestId;
import com.ericsson.oss.cms.test.legacy.operators.LegacyApiOperator;
import com.google.inject.Inject;

public class LegacyAutomationRunner extends TorTestCaseHelper implements TestCase {

    private static final String TEST_TITLE = "Legacy Perl automation test suite";

    private static final String LOG_FILE_MSG = "LOG FILE:: /opt/ericsson/atoss/tas/WR_CMS/results/";

    @Inject
    private LegacyApiOperator operator;

    @BeforeSuite
    public void setupSuite() throws IOException {
        operator.installTestSuite();
    }

    @Context(context = { Context.API })
    @Test
    @DataDriven(name = "stamping")
    public void execute(@Input("testFile") final String testFile, @TestId @Input("testCaseId") final String testCaseId) {
        setTestCase(testCaseId, TEST_TITLE);

        setTestStep("Execute legacy test case");
        final String stdOut = operator.executeTest(testFile, testCaseId);
        assertThat(stdOut, containsString(LOG_FILE_MSG));

        setTestStep("Read log file");
        final String testOutput = operator.getTestOutput(stdOut);
        final String testDesc = operator.getTestCaseDescription(testCaseId, testOutput);

        setTestCase(testCaseId, testDesc);
        assertThat(testOutput, containsString(LegacyApiOperator.TEST_SUCCESS_MSG));
    }

    @AfterSuite
    public void tearDownAfterSuite() {
        operator.deleteTestSuite();
    }
}