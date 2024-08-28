package com.ericsson.oss.cms.test.legacy.operators;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Path;

import javax.inject.Singleton;

import org.apache.commons.io.FileUtils;
import org.apache.log4j.Logger;

import com.ericsson.cifwk.taf.annotations.Context;
import com.ericsson.cifwk.taf.annotations.Operator;
import com.ericsson.cifwk.taf.handlers.RemoteFileHandler;
import com.ericsson.cifwk.taf.tools.cli.CLICommandHelper;
import com.ericsson.oss.cms.test.legacy.ResourceExtractor;
import com.ericsson.oss.taf.hostconfigurator.HostGroup;
import com.ericsson.oss.taf.hostconfigurator.OssHost;
import com.ericsson.cifwk.taf.data.*;

@Operator(context = Context.API)
@Singleton
public class LegacyApiOperator implements LegacyOperator {

    public static final String TEST_SUCCESS_MSG = "PASSED";

    private static final String TEST_DIR_NAME = "WR_CMS";

    private static final String TEST_DIR_PATH = "/opt/ericsson/atoss/tas/";

    private static final String TEST_DIR_FULL_PATH = TEST_DIR_PATH + TEST_DIR_NAME + "/";

    private static final String TEST_ID_FLAG = " -t ";

    private static final String LOG_FILE_PREFIX = "LOG FILE:: ";

    private static final String LOG_LINE_PREFIX = " :: ";

    private static final String TEST_CLEAN_UP_MSG = "CLEAN UP: ";

    private final OssHost host = HostGroup.getOssmaster();
	
	private final RemoteFileHandler remoteFileHanlder = new RemoteFileHandler(host,host.getNmsadmUser());	

    private final CLICommandHelper executor = new CLICommandHelper(host,host.getNmsadmUser());

    private final Logger log = Logger.getLogger(this.getClass());

    @Override
    public void installTestSuite() throws IOException {
        deleteTestSuite();

        final URL resource = this.getClass().getResource("/" + TEST_DIR_NAME);
        final File testSuiteDir = this.getLocalTestSuiteDirectory(resource);

        copyDirectoryToRemote(testSuiteDir, TEST_DIR_PATH);
    }

    private File getLocalTestSuiteDirectory(final URL resource) throws IOException {
        if (resource.toString().startsWith("jar")) {
            log.debug("Test suite is in compiled jar file: " + resource.toString());
            return this.extractSuiteFromJar(resource);
        } else {
            log.debug("Test suite is in build output directory: " + resource.toString());
            return new File(resource.getPath());
        }
    }

    private File extractSuiteFromJar(final URL resource) throws IOException {
        final File testSuiteDir = ResourceExtractor.extract(resource, TEST_DIR_NAME);
        FileUtils.forceDeleteOnExit(testSuiteDir);

        return testSuiteDir;
    }

    private void copyDirectoryToRemote(final File localDir, final String remoteDir) {
        final String createDir = remoteDir + localDir.getName() + "/";
        log.debug("Creating directory on remote server: " + createDir);
        executor.simpleExec("mkdir -p " + createDir);
        copyToRemote(localDir, createDir);
    }

    private void copyToRemote(final File localFile, final String remoteDir) {
        for (final File file : localFile.listFiles()) {
            if (file.isDirectory()) {
                copyDirectoryToRemote(file, remoteDir);
            } else {
                log.debug("Copying local file to remote server: " + file);
                remoteFileHanlder.copyLocalFileToRemote(file.getAbsolutePath(), remoteDir, file.getParent());
            }
        }
    }

    @Override
    public String getTestOutput(final String stdout) {
        final String logFile = getLogFilePath(stdout);
        final Path localLogFile = copyTestLogToLocal(logFile);

        return readLogContents(localLogFile);
    }

    private String getLogFilePath(final String stdout) {
        final int indexOfLogPath = stdout.indexOf(LOG_FILE_PREFIX) + LOG_FILE_PREFIX.length();

        final String logFile = stdout.substring(indexOfLogPath).trim();
        log.debug("Log file location: " + logFile);

        return logFile;
    }

    private Path copyTestLogToLocal(final String logFile) {
        Path localLogFile = null;
        try {
            localLogFile = Files.createTempFile(null, null);
            remoteFileHanlder.copyRemoteFileToLocal(logFile, localLogFile.toString());
        } catch (final IOException e) {
            log.error("Could not copy test result file to local filesystem.", e);
        }

        return localLogFile;
    }

    private String readLogContents(final Path localResultsFile) {
        final StringBuilder testOutput = new StringBuilder();

        try (BufferedReader reader = Files.newBufferedReader(localResultsFile, Charset.defaultCharset())) {
            while (reader.ready()) {
                final String line = reader.readLine();
                if (line.contains(TEST_CLEAN_UP_MSG)) {
                    return TEST_SUCCESS_MSG;
                }
                testOutput.append(line).append("\n");
            }
        } catch (final IOException e) {
            log.error("Could not read the test result file.", e);
        }

        return testOutput.toString();
    }

    @Override
    public String getTestCaseDescription(final String testCaseId, final String logOutput) {
        for (final String line : logOutput.split("\n")) {
            if (line.contains(testCaseId)) {
                log.debug("Test case description from log: " + line);
                final int startOfLine = line.indexOf(LOG_LINE_PREFIX) + LOG_LINE_PREFIX.length();
                return line.substring(startOfLine);
            }
        }
        return null;
    }

    @Override
    public void deleteTestSuite() {
        if (remoteFileHanlder.remoteFileExists(TEST_DIR_FULL_PATH)) {
            log.debug("Deleting test suite from remote server: " + TEST_DIR_FULL_PATH);
            executor.simpleExec("rm -rf " + TEST_DIR_FULL_PATH);
        }
    }

    @Override
    public String executeTest(final String testFile, final String testCaseId) {

        final String testCmd = TEST_DIR_FULL_PATH + testFile + TEST_ID_FLAG + testCaseId;
        final String fullCmd = String.format("tcsh -c '%s ; exit $?'", testCmd);

        return executor.simpleExec(fullCmd);
    }
}