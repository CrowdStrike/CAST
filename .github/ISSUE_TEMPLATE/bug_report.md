# CRITICAL
False-negative (failed to identify) reports without the appropriate details below will be summarily closed as off-topic.

## All bugs
__Describe the bug__

A clear and concise description of what the bug is.

__What version of CAST are you running__

Please indicate both version and platform.

__How are you invoking CAST__

Be precise, include the complete command line or identify what wrapper script you are using.

## False-negative

If this is not a bug about a failed detection, please delete this section.

__Fully qualified path to the presumed-vulnerable archive and its SHA256 checksum__

For example:
`c830cde8f929c35dad42cbdb6b28447df69ceffe99937bf420d32424df4d076a C:\Users\tommy\log4j-core-2.2.jar`

__Precise version of the archive__

log4j-2.2

### Option 1: attach a copy of the archive or provide a public URL to download
This is the preferred route

### Option 2: provide precise details
__Full listing of the archive__

```
# unzip -l log4j-core-2.2.jar 
Archive:  log4j-core-2.2.jar
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  02-22-2015 15:20   META-INF/
    12712  02-22-2015 15:20   META-INF/MANIFEST.MF
        0  02-22-2015 15:17   META-INF/org/
        0  02-22-2015 15:17   META-INF/org/apache/
...
        0  02-22-2015 15:20   META-INF/maven/org.apache.logging.log4j/log4j-core/
    15743  02-22-2015 15:16   META-INF/maven/org.apache.logging.log4j/log4j-core/pom.xml
      117  02-22-2015 15:20   META-INF/maven/org.apache.logging.log4j/log4j-core/pom.properties
---------                     -------
  1713490                     623 files
```

__Full checksum listing of the archive__

```
# unzip -d log4j-core-2.2 log4j-core-2.2.jar
# sha256deep -r ./log4j-core-2.2
75708a8f54a7c81c6ee6bb12d1db727678ce7e8b9d6d8befba61be43b12b894c  log4j-core-2.2/Log4j-events.xsd
b3e58314dff1efe32278e47fb48bc6f7b8c66ca4565a9427de0e0f38fddbe7a1  log4j-core-2.2/Log4j-config.xsd
ad0c4bf05e8ddc0f962d9b095d132eb953efc0b5061c46da3b5a7b6a90bc73c8  log4j-core-2.2/Log4j-levels.xsd
9526d450bb5d1997295f5c3cdda79b007c49995f6ff0e412725205942bae36b0  log4j-core-2.2/org/apache/logging/log4j/core/Logger.class
95f1f59e81ea589c5d7a511914b9ab019d3a0106ecb3e61911f6b4a76e1088b1  log4j-core-2.2/org/apache/logging/log4j/core/appender/RandomAccessFileManager$DummyOutputStream.class
...
```

__Sub-archive reports__

If the false-negative is in a JAR inside of the outer JAR, please provide the same details above for *both*

False-negative reports without the above details will be summarily closed as off-topic. This was intentionally stated twice.


## Normal bug
__To Reproduce__
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

__Expected behavior__
A clear and concise description of what you expected to happen.

__Screenshots or logs__
If applicable, add screenshots or logs to help explain your problem.

__Desktop (please complete the following information):__
 - OS: [e.g. iOS]
 - Browser [e.g. chrome, safari]
 - Version [e.g. 22]

__Smartphone (please complete the following information):__
 - Device: [e.g. iPhone6]
 - OS: [e.g. iOS8.1]
 - Browser [e.g. stock browser, safari]
 - Version [e.g. 22]

__Additional context__
Add any other context about the problem here.
