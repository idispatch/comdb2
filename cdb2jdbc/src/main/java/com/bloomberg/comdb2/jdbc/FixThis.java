package com.bloomberg.comdb2.jdbc;

import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.FileWriter;
import java.io.PrintStream;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;

public class FixThis {

    public static void notSupported(String value) throws SQLException {
        log("Operation not supported: " + value);
        //throw new SQLFeatureNotSupportedException(value);
    }

    public static void log(String value) {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter("/home/okosenkov/Desktop/cdb2jdbc.log", true))) {
            if (value == null) {
                writer.write("<null>\n");
            } else {
                writer.write(value);
                if (!value.endsWith("\n")) {
                    writer.newLine();
                }
            }
        } catch (Exception e) {
            System.exit(1);
        }
    }

    public static Exception logException(Exception value) {
        log(value);
        return value;
    }

    public static SQLException logException(SQLException value) {
        log(value);
        return value;
    }

    public static void log(Exception value) {
        log("Exception: " + (value == null ? "<null exception>" : exceptionStacktraceToString(value)));
    }

    private static String exceptionStacktraceToString(Exception e) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (PrintStream ps = new PrintStream(baos)) {
            e.printStackTrace(ps);
        }
        return baos.toString();
    }
}
