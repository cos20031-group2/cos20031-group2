# Smart Fleet Management System — Local Setup

## Prerequisites
- XAMPP installed, with **Apache** and **MySQL** running.
- Extract the GitHub ZIP file (cos20031-group2-main.zip).
- Both project folders placed inside `C:\xampp\htdocs\`, side by side:
  Note: You must extract cos20031-smarfleet out of the main folder and rename the parent repository folder to exactly cos20031-group2 for the path names to match.
  ```
  htdocs\
      cos20031-group2\      <- schema.sql, triggers, import.bat, seed_data\
      cos20031-smarfleet\   <- the dashboard app (config\, includes\, auth\, dashboards\)
  ```

## 1. Import the database
1. Open the **XAMPP Control Panel** → click **Shell**.
2. `cd` into `cos20031-group2`:
   ```
   cd C:\xampp\htdocs\cos20031-group2
   ```
   (Ensure your directory name matches this path exactly or the script will fail).
3. Run:
   ```
   import.bat
   ```
4. If it fails, it stops at the failing step and shows the exact MySQL error — fix that and re-run.
   1.Troubleshooting: If MySQL fails to start in XAMPP, check that port 3306 is not being used by another local database instance.

If your MySQL `root` user has a password, edit `import.bat`'s `set MYSQLPW=` line to `set MYSQLPW=-pYourPassword` (no space after `-p`).

## 2. Run the app
Go to your browser and access:
```
http://localhost/cos20031-smarfleet/auth/login.php
```

## 3. Demo accounts
All passwords: `1234`

| Role | Username |
|---|---|
| Driver | `DriverD0001` |
| Mechanic | `MechanicME0001` |
| Safety Staff | `SafetyStaff0001` |
| Fleet Manager | `FleetManager001` |
| Workshop Manager | `WorkshopManager001` |
> To log in as a different role, click **Log out** first — visiting the login page while already logged in just redirects you back to your current dashboard without checking new credentials.
