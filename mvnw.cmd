@echo off
rem Maven wrapper script for TrafficFlowX
rem Ensure valid JAVA_HOME
if not exist "%JAVA_HOME%\bin\java.exe" (
    set "JAVA_HOME=C:\Program Files\Java\jdk-26.0.2.1"
)
if exist "%USERPROFILE%\.maven\apache-maven-3.9.9\bin\mvn.cmd" (
    "%USERPROFILE%\.maven\apache-maven-3.9.9\bin\mvn.cmd" %*
) else if exist "C:\Users\Soyon Das\.maven\apache-maven-3.9.9\bin\mvn.cmd" (
    "C:\Users\Soyon Das\.maven\apache-maven-3.9.9\bin\mvn.cmd" %*
) else (
    mvn %*
)
