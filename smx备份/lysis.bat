@echo off
 
set DIR=%~dp0
set ROOT=%DIR%
 
for /f "delims=" %%f in ('dir  /b/a-d/s  %ROOT%\*.smx') do (
 
echo %%f
java -jar E:\temp\lysis-java.jar %%f >> temp233.txt

)
 
pause