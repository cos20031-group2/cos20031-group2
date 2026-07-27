@echo off
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
REM   5. Watch the output — it prints which file it's importing.
REM      If something fails, it stops immediately and tells you
REM      which step failed, and the exact MySQL error above it.
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

echo [1/16] schema.sql
mysql -u root %MYSQLPW% %DB% < "%BASE%\schema.sql"
if errorlevel 1 goto :error

echo [2/16] 1_vehicle_assignment_triggers.sql
mysql -u root %MYSQLPW% %DB% < "%BASE%\1_vehicle_assignment_triggers.sql"
if errorlevel 1 goto :error

echo [3/16] 2_maintenance_and_alert_triggers.sql
mysql -u root %MYSQLPW% %DB% < "%BASE%\2_maintenance_and_alert_triggers.sql"
if errorlevel 1 goto :error

echo [4/16] 3_driver_eligibility_and_safety_event_triggers.sql
mysql -u root %MYSQLPW% %DB% < "%BASE%\3_driver_eligibility_and_safety_event_triggers.sql"
if errorlevel 1 goto :error

echo [5/16] 4_review_coaching_and_scoring_triggers.sql
mysql -u root %MYSQLPW% %DB% < "%BASE%\4_review_coaching_and_scoring_triggers.sql"
if errorlevel 1 goto :error

echo [6/16] 5_workshop_operations_triggers.sql
mysql -u root %MYSQLPW% %DB% < "%BASE%\5_workshop_operations_triggers.sql"
if errorlevel 1 goto :error

echo.
echo === Importing seed data ===

echo [7/16] 01_reference.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\01_reference.sql"
if errorlevel 1 goto :error

echo [8/16] 02_core_entities.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\02_core_entities.sql"
if errorlevel 1 goto :error

echo [9/16] 03_certifications.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\03_certifications.sql"
if errorlevel 1 goto :error

echo [10/16] 04_score_init.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\04_score_init.sql"
if errorlevel 1 goto :error

echo [11/16] 05_vehicle_assignments.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\05_vehicle_assignments.sql"
if errorlevel 1 goto :error

echo [12/16] 06_alerts_schedules.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\06_alerts_schedules.sql"
if errorlevel 1 goto :error

echo [13/16] 07_maintenance.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\07_maintenance.sql"
if errorlevel 1 goto :error

echo [14/16] 08_safety_events.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\08_safety_events.sql"
if errorlevel 1 goto :error

echo [15/16] 09_reviews_coaching.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\09_reviews_coaching.sql"
if errorlevel 1 goto :error

echo [16/16] 10_app_users.sql
mysql -u root %MYSQLPW% %DB% < "%SEED%\10_app_users.sql"
if errorlevel 1 goto :error

goto :end

:error
echo.
echo *** Something failed! Check the error above to see which file caused it. ***
pause
exit /b 1

:end
echo.
echo === All done! Database "%DB%" imported successfully. ===
pause
