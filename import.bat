@echo off
setlocal EnableDelayedExpansion
 
REM ============================================================
REM  SmartFleet Database Import Script
REM ============================================================
REM  HOW TO RUN THIS (for every team member):
REM
REM   1. Make sure this import.bat file is placed directly INSIDE
REM      the "cos20031-group2" folder (same level as schema.sql).
REM      Your folder should look like:
REM         cos20031-group2\
REM             import.bat          <-- this file
REM             schema.sql
REM             1_vehicle_assignment_triggers.sql
REM             ...
REM             seed_data\
REM                 data_generator_py\
REM                     output\
REM                         01_reference.sql
REM                         ...
REM
REM   2. Open the XAMPP Control Panel and click "Shell"
REM      (this opens a CMD window with mysql.exe already on PATH)
REM
REM   3. Navigate into the cos20031-group2 folder. For example, if
REM      your project is in C:\xampp\htdocs\homework, run:
REM         cd C:\xampp\htdocs\homework\cos20031-group2
REM
REM   4. Run the script by typing its name:
REM         import.bat
REM
REM   5. Watch the output — for every file it now prints:
REM         [step/17] filename.sql  (size in KB)
REM             -> done in X.XXs  (step of 17 complete)
REM      If something fails, it stops immediately, tells you which
REM      step and file failed, and the exact MySQL error is printed
REM      just above it. A grand total time is printed at the end.
REM
REM  NOTE: assumes root has NO password (default XAMPP setting).
REM  If your root user HAS a password, edit the line below that
REM  says "set MYSQLPW=" and put it between the quotes, e.g.:
REM      set MYSQLPW=-pMyPassword123
REM  (no space between -p and the password)
REM ============================================================
 
set DB=SmartFleet
set BASE=.
set SEED=%BASE%\seed_data\data_generator_py\output
set MYSQLPW=
set TOTAL_STEPS=17
set STEP_NUM=0
set SCRIPT_START=!TIME!

echo.
echo === Dropping database "%DB%" if it already exists ===
mysql -u root %MYSQLPW% -e "DROP DATABASE IF EXISTS %DB%;"
if errorlevel 1 goto :error

echo.
echo === Creating database "%DB%" if it doesn't already exist ===
mysql -u root %MYSQLPW% -e "CREATE DATABASE IF NOT EXISTS %DB%;"
if errorlevel 1 goto :error
 
echo.
echo === Increasing max_allowed_packet for this session (fixes "packet bigger than max_allowed_packet" errors) ===
mysql -u root %MYSQLPW% -e "SET GLOBAL max_allowed_packet=268435456;"
if errorlevel 1 goto :error
 
echo.
echo === Importing schema and triggers ===
call :step "schema.sql" "%BASE%\schema.sql"
call :step "approved_indexes.sql" "%BASE%\approved_indexes.sql"
call :step "1_vehicle_assignment_triggers.sql" "%BASE%\1_vehicle_assignment_triggers.sql"
call :step "2_maintenance_and_alert_triggers.sql" "%BASE%\2_maintenance_and_alert_triggers.sql"
call :step "3_driver_eligibility_and_safety_event_triggers.sql" "%BASE%\3_driver_eligibility_and_safety_event_triggers.sql"
call :step "4_review_coaching_and_scoring_triggers.sql" "%BASE%\4_review_coaching_and_scoring_triggers.sql"
call :step "5_workshop_operations_triggers.sql" "%BASE%\5_workshop_operations_triggers.sql"
 
echo.
echo === Importing seed data ===
call :step "01_reference.sql" "%SEED%\01_reference.sql"
call :step "02_core_entities.sql" "%SEED%\02_core_entities.sql"
call :step "03_certifications.sql" "%SEED%\03_certifications.sql"
call :step "04_score_init.sql" "%SEED%\04_score_init.sql"
call :step "05_vehicle_assignments.sql" "%SEED%\05_vehicle_assignments.sql"
call :step "06_alerts_schedules.sql" "%SEED%\06_alerts_schedules.sql"
call :step "07_maintenance.sql" "%SEED%\07_maintenance.sql"
call :step "08_safety_events.sql" "%SEED%\08_safety_events.sql"
call :step "09_reviews_coaching.sql" "%SEED%\09_reviews_coaching.sql"
call :step "10_app_users.sql" "%SEED%\10_app_users.sql"
 
goto :end
 
REM ------------------------------------------------------------
REM  :step  "display name" "path to .sql file"
REM  Runs one import, prints its size, timing, and progress,
REM  and jumps to :error automatically if it fails.
REM ------------------------------------------------------------
:step
set /a STEP_NUM+=1
set "SNAME=%~1"
set "SFILE=%~2"
 
if not exist "!SFILE!" (
    echo.
    echo [!STEP_NUM!/%TOTAL_STEPS%] !SNAME! ... FILE NOT FOUND: !SFILE!
    goto :error
)
 
for %%F in ("!SFILE!") do set /a SIZE_KB=%%~zF/1024
 
echo.
echo [!STEP_NUM!/%TOTAL_STEPS%] !SNAME!  (!SIZE_KB! KB)
set "T0=!TIME!"
mysql -u root %MYSQLPW% %DB% < "!SFILE!"
set "RC=!ERRORLEVEL!"
set "T1=!TIME!"
call :elapsed "!T0!" "!T1!" DUR
echo         -^> done in !DUR!  (!STEP_NUM! of %TOTAL_STEPS% complete)
 
if not "!RC!"=="0" goto :error
exit /b 0
 
REM ------------------------------------------------------------
REM  :elapsed  "start time" "end time" RESULTVAR
REM  Computes a human-readable duration like "3.42s"
REM ------------------------------------------------------------
:elapsed
setlocal
call :time_to_cs "%~1" cs1
call :time_to_cs "%~2" cs2
set /a "diff=cs2-cs1"
if !diff! lss 0 set /a "diff+=8640000"
set /a "secs=diff/100"
set /a "cs=diff%%100"
endlocal & set "%~3=%secs%.%cs%s"
exit /b
 
:time_to_cs
setlocal
set "t=%~1"
for /f "tokens=1-4 delims=:.," %%a in ("%t%") do (
    set "h=%%a"
    set "m=%%b"
    set "s=%%c"
    set "c=%%d"
)
if "!h:~0,1!"==" " set "h=0!h:~1!"
if not defined c set "c=0"
set /a "h=1!h!-100"
set /a "m=1!m!-100"
set /a "s=1!s!-100"
set /a "c=1!c!-100"
set /a "result=(h*3600+m*60+s)*100+c"
endlocal & set "%~2=%result%"
exit /b
 
:error
echo.
if !STEP_NUM! GTR 0 (
    echo *** Import failed at step !STEP_NUM! of %TOTAL_STEPS%: !SNAME! ***
) else (
    echo *** Setup step failed before any files were imported. ***
)
echo *** Check the MySQL error message above for details. ***
pause
exit /b 1
 
:end
set "SCRIPT_END=!TIME!"
call :elapsed "!SCRIPT_START!" "!SCRIPT_END!" TOTALDUR
echo.
echo === All done! Database "%DB%" imported successfully (%TOTAL_STEPS% files, total time !TOTALDUR!). ===
pause
 