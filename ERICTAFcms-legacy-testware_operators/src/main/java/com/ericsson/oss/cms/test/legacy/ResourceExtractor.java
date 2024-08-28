/**
 * -----------------------------------------------------------------------
 *     Copyright (C) 2014 LM Ericsson Limited.  All rights reserved.
 * -----------------------------------------------------------------------
 */
package com.ericsson.oss.cms.test.legacy;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URL;
import java.nio.file.Files;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.apache.log4j.Logger;

public class ResourceExtractor {

    private final static Logger logger = Logger.getLogger(ResourceExtractor.class);

    public static File extract(final URL resource, final String extract) throws IOException {
        final String resourcePath = resource.getPath();
        final String jarPath = resourcePath.substring(0, resourcePath.indexOf('!'));
        final URL url = new URL(jarPath);
        logger.debug("Jar file: " + jarPath);
        final ZipInputStream zis = new ZipInputStream(new BufferedInputStream(url.openStream()));
        ZipEntry ze = null;

        final File tempHoldingDir = Files.createTempDirectory(extract).toFile().getAbsoluteFile();
        logger.debug("Copying test suite to temp directory: " + tempHoldingDir);

        while ((ze = zis.getNextEntry()) != null) {
            extractFiles(extract, zis, ze, tempHoldingDir);
        }
        zis.close();
        return new File(tempHoldingDir, extract);
    }

    private static void extractFiles(final String extract, final ZipInputStream zis, final ZipEntry ze, final File tempHoldingDir) throws IOException {
        if (ze.getName().startsWith(extract)) {
            if (ze.isDirectory()) {
                logger.debug("Creating directory in temp directory: " + tempHoldingDir + File.separator + ze.getName());
                new File(tempHoldingDir, ze.getName()).mkdir();
            } else {
                extractFile(zis, ze, tempHoldingDir);
            }
        }
    }

    private static void extractFile(final ZipInputStream zis, final ZipEntry ze, final File tempHoldingDir) throws IOException {
        // extract them to the directory
        final int size = (int) ze.getSize();
        final byte[] buffer = new byte[size];
        int bytesRead = 0;
        int chunk = 0;
        while (size - bytesRead > 0) {
            chunk = zis.read(buffer, bytesRead, size - bytesRead);
            if (chunk == -1) {
                break;
            }
            bytesRead += chunk;
        }
        // write to file
        final String toFileName = tempHoldingDir.getPath() + File.separator + ze.getName();
        logger.debug("Copying file to temp directory: " + toFileName);

        final File compatFile = new File(toFileName);
        final FileOutputStream fos = new FileOutputStream(compatFile);
        fos.write(buffer);
        fos.close();
    }
}
