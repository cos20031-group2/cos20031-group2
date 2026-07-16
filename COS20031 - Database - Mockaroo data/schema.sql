-- ==========================================
-- 1. Lookup & Reference Tables (No FKs)
-- ==========================================

CREATE TABLE Location (
    LocationID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    LocationName VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE VehicleCategory (
    VehicleCategoryID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VehicleCategory VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE VehicleStatus (
    VehicleStatusID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VehicleStatus VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE DriverCertificationType (
    DriverCertificationTypeID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DriverCertificationType VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT NULL
);

CREATE TABLE EventType (
    EventTypeID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    EventType VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE EventSeverity (
    SeverityID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    SeverityLevel VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE AlertType (
    AlertTypeID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    AlertType VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE MechanicCertificationType (
    MechanicCertificationTypeID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MechanicCertificationType VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE SafetyStaff (
    ReviewStaffID MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(255) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL
);

CREATE TABLE Supplier (
    SupplierID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL UNIQUE,
    ContactInfo VARCHAR(255) NOT NULL,
    Address VARCHAR(255) NOT NULL,
    DeliveryLeadTime SMALLINT UNSIGNED NOT NULL
);

CREATE TABLE Part (
    PartNumber INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    PartName VARCHAR(100) NOT NULL,
    Description TEXT NULL,
    CurrentStock SMALLINT UNSIGNED NOT NULL,
    ReorderThreshold SMALLINT UNSIGNED NOT NULL,
    UnitPrice BIGINT UNSIGNED NOT NULL
);

-- ==========================================
-- 2. Core Entities & Level 1 Dependencies
-- ==========================================

CREATE TABLE Depot (
    DepotID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DepotName VARCHAR(100) NOT NULL UNIQUE,
    Address VARCHAR(255) NOT NULL,
    LocationID SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT FK_Depot_Location FOREIGN KEY (LocationID) REFERENCES Location(LocationID)
);

CREATE TABLE ActivityType (
    ActivityTypeID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ActivityType VARCHAR(255) NOT NULL UNIQUE,
    RequiredMechanicCertification SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT FK_AT_CertType FOREIGN KEY (RequiredMechanicCertification) REFERENCES MechanicCertificationType(MechanicCertificationTypeID)
);

CREATE TABLE VehicleCertificationRequirement (
    VehicleCategoryID SMALLINT UNSIGNED,
    DriverCertificationTypeID SMALLINT UNSIGNED,
    PRIMARY KEY (VehicleCategoryID, DriverCertificationTypeID),
    CONSTRAINT FK_VCR_Category FOREIGN KEY (VehicleCategoryID) REFERENCES VehicleCategory(VehicleCategoryID),
    CONSTRAINT FK_VCR_CertType FOREIGN KEY (DriverCertificationTypeID) REFERENCES DriverCertificationType(DriverCertificationTypeID)
);

CREATE TABLE Workshop (
    WorkshopID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DepotID SMALLINT UNSIGNED NOT NULL UNIQUE,
    Name VARCHAR(100) NOT NULL,
    CONSTRAINT FK_Workshop_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID)
);

CREATE TABLE Vehicle (
    VIN VARCHAR(17) PRIMARY KEY,
    RegistrationNumber VARCHAR(20) NOT NULL UNIQUE,
    CategoryID SMALLINT UNSIGNED NOT NULL,
    Model VARCHAR(100) NOT NULL,
    Manufacturer VARCHAR(100) NOT NULL,
    YearOfManufacture YEAR NOT NULL,
    Odometer MEDIUMINT UNSIGNED NOT NULL,
    DepotID SMALLINT UNSIGNED NOT NULL,
    OperationalStatus SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT FK_Vehicle_Category FOREIGN KEY (CategoryID) REFERENCES VehicleCategory(VehicleCategoryID),
    CONSTRAINT FK_Vehicle_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID),
    CONSTRAINT FK_Vehicle_Status FOREIGN KEY (OperationalStatus) REFERENCES VehicleStatus(VehicleStatusID)
);

CREATE TABLE Driver (
    DriverID VARCHAR(20) PRIMARY KEY,
    FullName VARCHAR(255) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL,
    CurrentDepotID SMALLINT UNSIGNED NULL,
    EmploymentStatus ENUM('Active', 'Inactive', 'Suspended', 'Terminated') NOT NULL,
    EmergencyContactDetails VARCHAR(255) NOT NULL,
    CONSTRAINT FK_Driver_Depot FOREIGN KEY (CurrentDepotID) REFERENCES Depot(DepotID)
);

CREATE TABLE Mechanic (
    MechanicID VARCHAR(20) PRIMARY KEY,
    FullName VARCHAR(255) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL,
    WorkshopID SMALLINT UNSIGNED NOT NULL,
    EmploymentStatus ENUM('Active', 'Inactive', 'Suspended', 'Terminated') NOT NULL,
    CONSTRAINT FK_Mechanic_Workshop FOREIGN KEY (WorkshopID) REFERENCES Workshop(WorkshopID)
);

-- ==========================================
-- 3. Assignments, Events & Maintenance
-- ==========================================

CREATE TABLE VehicleAssignment (
    AssignmentID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    DriverID VARCHAR(20) NOT NULL,
    DepotID SMALLINT UNSIGNED NOT NULL,
    IssueDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    IsActive BOOLEAN NOT NULL,
    CONSTRAINT FK_VA_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_VA_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID),
    CONSTRAINT FK_VA_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID)
);

CREATE TABLE SafetyEvent (
    EventID VARCHAR(100) PRIMARY KEY,
    DriverID VARCHAR(20) NOT NULL,
    VIN VARCHAR(17) NOT NULL,
    DepotID SMALLINT UNSIGNED NOT NULL,
    EventTimestamp TIMESTAMP NOT NULL,
    EventTypeID SMALLINT UNSIGNED NOT NULL,
    SeverityID SMALLINT UNSIGNED NOT NULL,
    Odometer MEDIUMINT UNSIGNED NOT NULL,
    ReviewState ENUM('Pending', 'Assigned', 'In Review', 'Completed', 'No Review Required') DEFAULT 'No Review Required' NOT NULL,
    CONSTRAINT FK_SE_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID),
    CONSTRAINT FK_SE_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_SE_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID),
    CONSTRAINT FK_SE_EventType FOREIGN KEY (EventTypeID) REFERENCES EventType(EventTypeID),
    CONSTRAINT FK_SE_Severity FOREIGN KEY (SeverityID) REFERENCES EventSeverity(SeverityID)
);

CREATE TABLE CoachingRecord (
    CoachingRecordID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DriverID VARCHAR(20) NOT NULL,
    CoachingType ENUM('Safety Coaching', 'Retraining', 'Licence Review') NOT NULL,
    Date DATE NOT NULL,
    Outcome ENUM('Passed', 'Failed', 'In Progress', 'Pending') DEFAULT 'Pending' NOT NULL,
    CONSTRAINT FK_CR_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID)
);

CREATE TABLE PredictiveAlert (
    AlertID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    AlertTypeID SMALLINT UNSIGNED NOT NULL,
    DateGenerated DATETIME NOT NULL,
    ActionTaken TEXT NULL,
    AlertStatus ENUM('Unresolved', 'Acknowledged', 'Scheduled For Inspection', 'Urgent Repair Standby', 'Resolved') DEFAULT 'Unresolved' NOT NULL,
    CONSTRAINT FK_PA_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_PA_AlertType FOREIGN KEY (AlertTypeID) REFERENCES AlertType(AlertTypeID)
);

CREATE TABLE MaintenanceJob (
    JobID VARCHAR(255) PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    WorkshopID SMALLINT UNSIGNED NOT NULL,
    DateOpened DATETIME NOT NULL,
    DateClosed DATETIME NULL,
    Downtime DECIMAL(12,4) NOT NULL,
    TotalCost BIGINT UNSIGNED NULL,
    CONSTRAINT FK_MJ_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_MJ_Workshop FOREIGN KEY (WorkshopID) REFERENCES Workshop(WorkshopID)
);

CREATE TABLE MaintenanceActivity (
    ActivityID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    JobID VARCHAR(255) NOT NULL,
    ActivityTypeID SMALLINT UNSIGNED NOT NULL,
    DiagnosticResult TEXT NULL,
    RepeatedFaultFlag BOOLEAN NOT NULL,
    WarrantyFlag BOOLEAN NOT NULL,
    LinkedAlertID INT UNSIGNED NULL,
    CONSTRAINT FK_MA_Job FOREIGN KEY (JobID) REFERENCES MaintenanceJob(JobID),
    CONSTRAINT FK_MA_ActivityType FOREIGN KEY (ActivityTypeID) REFERENCES ActivityType(ActivityTypeID),
    CONSTRAINT FK_MA_Alert FOREIGN KEY (LinkedAlertID) REFERENCES PredictiveAlert(AlertID)
);

-- ==========================================
-- 4. Certifications & Reviews
-- ==========================================

CREATE TABLE DriverCertification (
    DriverCertificationID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DriverID VARCHAR(20) NOT NULL,
    DriverCertificationTypeID SMALLINT UNSIGNED NOT NULL,
    IssueDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    RevocationDate DATE NULL,
    Status ENUM('Active', 'Revoked', 'Expired', 'Voided', 'Reinstated') DEFAULT 'Active' NOT NULL,
    StatusNotes TEXT NULL,
    CONSTRAINT UC_DriverCertification UNIQUE (DriverID, DriverCertificationTypeID, IssueDate, ExpiryDate),
    CONSTRAINT FK_DC_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID),
    CONSTRAINT FK_DC_CertType FOREIGN KEY (DriverCertificationTypeID) REFERENCES DriverCertificationType(DriverCertificationTypeID)
);

CREATE TABLE MechanicCertification (
    MechanicCertificationID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MechanicID VARCHAR(20) NOT NULL,
    MechanicCertificationTypeID SMALLINT UNSIGNED NOT NULL,
    IssueDate DATE NOT NULL,
    ExpiryDate DATE NOT NULL,
    RevocationDate DATE NULL,
    Status ENUM('Active', 'Revoked', 'Expired', 'Voided', 'Reinstated') DEFAULT 'Active' NOT NULL,
    StatusNotes TEXT NULL,
    CONSTRAINT UC_MechanicCertification UNIQUE (MechanicID, MechanicCertificationTypeID, IssueDate, ExpiryDate),
    CONSTRAINT FK_MC_Mechanic FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID),
    CONSTRAINT FK_MC_CertType FOREIGN KEY (MechanicCertificationTypeID) REFERENCES MechanicCertificationType(MechanicCertificationTypeID)
);

CREATE TABLE EventReview (
    ReviewID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    EventID VARCHAR(100) NOT NULL,
    ReviewerStaffID MEDIUMINT UNSIGNED NOT NULL,
    Comments TEXT NULL,
    Recommendations TEXT NULL,
    Status ENUM('Unread', 'Read', 'Commented', 'Closed') DEFAULT 'Unread' NOT NULL,
    DateReviewed DATETIME NOT NULL,
    CONSTRAINT FK_ER_Event FOREIGN KEY (EventID) REFERENCES SafetyEvent(EventID),
    CONSTRAINT FK_ER_Staff FOREIGN KEY (ReviewerStaffID) REFERENCES SafetyStaff(ReviewStaffID)
);

-- ==========================================
-- 5. Penalties, Scores & Schedules
-- ==========================================

CREATE TABLE PenaltyRule (
    PenaltyRuleID SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    RuleType ENUM('Base', 'Conditional') NOT NULL,
    RuleDescription TEXT NULL,
    EventTypeID SMALLINT UNSIGNED NULL,
    SeverityID SMALLINT UNSIGNED NULL,
    MinEventCount TINYINT UNSIGNED NOT NULL,
    TimeWindowMonths TINYINT UNSIGNED NOT NULL,
    PenaltyPoints DECIMAL(5,2) NOT NULL,
    CONSTRAINT FK_PR_EventType FOREIGN KEY (EventTypeID) REFERENCES EventType(EventTypeID),
    CONSTRAINT FK_PR_Severity FOREIGN KEY (SeverityID) REFERENCES EventSeverity(SeverityID)
);

CREATE TABLE DriverMonthlySafetyScore (
    DriverMonthlySafetyScoreID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DriverID VARCHAR(20) NOT NULL,
    Month TINYINT UNSIGNED NOT NULL,
    Year YEAR NOT NULL,
    DepotID SMALLINT UNSIGNED NOT NULL,
    Score DECIMAL(5,2) NOT NULL,
    CONSTRAINT UC_DriverMonthlySafetyScore UNIQUE (DriverID, Month, Year),
    CONSTRAINT FK_DMSS_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID),
    CONSTRAINT FK_DMSS_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID)
);

CREATE TABLE DriverScorePenalty (
    ScorePenaltyID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DriverMonthlySafetyScoreID INT UNSIGNED NOT NULL,
    PenaltyRuleID SMALLINT UNSIGNED NOT NULL,
    EventID VARCHAR(100) NOT NULL,
    PointsDeducted DECIMAL(5,2) NOT NULL,
    DateApplied DATETIME NOT NULL,
    CONSTRAINT FK_DSP_Score FOREIGN KEY (DriverMonthlySafetyScoreID) REFERENCES DriverMonthlySafetyScore(DriverMonthlySafetyScoreID),
    CONSTRAINT FK_DSP_Rule FOREIGN KEY (PenaltyRuleID) REFERENCES PenaltyRule(PenaltyRuleID),
    CONSTRAINT FK_DSP_Event FOREIGN KEY (EventID) REFERENCES SafetyEvent(EventID)
);

CREATE TABLE ScheduledService (
    ScheduleID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    ScheduledDate DATE NOT NULL,
    Reason TEXT NULL,
    AlertID INT UNSIGNED NULL,
    Status ENUM('Scheduled', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Scheduled' NOT NULL,
    CONSTRAINT FK_SS_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_SS_Alert FOREIGN KEY (AlertID) REFERENCES PredictiveAlert(AlertID)
);

-- ==========================================
-- 6. Workshop Operations & Parts Tracking
-- ==========================================

CREATE TABLE MechanicWorkSession (
    SessionID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MechanicID VARCHAR(20) NOT NULL,
    ActivityID INT UNSIGNED NOT NULL,
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NULL,
    CONSTRAINT FK_MWS_Mechanic FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID),
    CONSTRAINT FK_MWS_Activity FOREIGN KEY (ActivityID) REFERENCES MaintenanceActivity(ActivityID)
);

CREATE TABLE WarrantyClaim (
    ClaimID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ActivityID INT UNSIGNED NOT NULL,
    ClaimSource VARCHAR(100) NOT NULL,
    ClaimDate DATE NOT NULL,
    Status ENUM('Pending', 'Approved', 'Rejected', 'Settled') DEFAULT 'Pending' NOT NULL,
    CONSTRAINT FK_WC_Activity FOREIGN KEY (ActivityID) REFERENCES MaintenanceActivity(ActivityID)
);

CREATE TABLE PartSupplier (
    PartNumber INT UNSIGNED,
    SupplierID SMALLINT UNSIGNED,
    IsPrimary BOOLEAN NOT NULL,
    UnitCost BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (PartNumber, SupplierID),
    CONSTRAINT FK_PS_Part FOREIGN KEY (PartNumber) REFERENCES Part(PartNumber),
    CONSTRAINT FK_PS_Supplier FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID)
);

CREATE TABLE ActivityPart (
    ActivityID INT UNSIGNED,
    PartNumber INT UNSIGNED,
    ClaimID INT UNSIGNED NULL,
    QuantityUsed SMALLINT UNSIGNED NOT NULL,
    UnitCost BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (ActivityID, PartNumber),
    CONSTRAINT FK_AP_Activity FOREIGN KEY (ActivityID) REFERENCES MaintenanceActivity(ActivityID),
    CONSTRAINT FK_AP_Part FOREIGN KEY (PartNumber) REFERENCES Part(PartNumber),
    CONSTRAINT FK_AP_Claim FOREIGN KEY (ClaimID) REFERENCES WarrantyClaim(ClaimID)
);

-- ==========================================
-- SEED DATA: Lookup & Reference Tables
-- ==========================================

-- 1. Location
INSERT INTO Location (LocationName) VALUES 
('Ha Noi'), 
('Da Nang'), 
('Ho Chi Minh City'), 
('Can Tho');

-- 2. VehicleCategory
INSERT INTO VehicleCategory (VehicleCategory) VALUES 
('Delivery Van'), 
('Refrigerated Truck'), 
('Electric Van'), 
('Service Vehicle'), 
('Heavy Transport Truck');

-- 3. VehicleStatus
INSERT INTO VehicleStatus (VehicleStatus) VALUES 
('Active'), 
('Available'), 
('Under Maintenance'), 
('Awaiting Inspection'), 
('Out Of Service'), 
('Retired');

-- 4. DriverCertificationType
INSERT INTO DriverCertificationType (DriverCertificationType) VALUES 
('Standard License'), 
('Heavy Vehicle License'), 
('Refrigerated Transport Certification'), 
('EV Certification'), 
('Hazardous Goods Certification');

-- 5. EventType
INSERT INTO EventType (EventType) VALUES 
('Harsh braking'), 
('Rapid acceleration'), 
('Excessive speeding'), 
('Sharp cornering'), 
('Excessive idling'), 
('Fatigue warnings'), 
('Seatbelt violations'), 
('Phone distraction alerts');

-- 6. EventSeverity
INSERT INTO EventSeverity (SeverityLevel) VALUES 
('Low'), 
('Medium'), 
('High'), 
('Critical');

-- 7. AlertType
INSERT INTO AlertType (AlertType) VALUES 
('Brake Wear Warning'), 
('Engine Overheating Risk'), 
('Battery Degradation'), 
('Oil Quality Deterioration'), 
('Transmission Fault Warning'), 
('Cooling System Anomaly'), 
('Tire Pressure Irregularity');

-- 8. ActivityType
INSERT INTO ActivityType (ActivityType, RequiredMechanicCertification) VALUES 
('Routine Inspection', 1), 
('Preventative Servicing', 1), 
('Diagnostic Testing', 1), 
('Emergency Repair', 1), 
('Component Replacement', 1), 
('EV Battery / Electrical Repair', 2), 
('Refrigeration System Repair', 3), 
('Heavy Vehicle Repair', 4);
-- Note: The RequiredMechanicCertification IDs above assume the MechanicCertificationType table 
-- is seeded in the exact order below (1=Standard, 2=EV, 3=Refrigeration, 4=Heavy).

-- 9. MechanicCertificationType
INSERT INTO MechanicCertificationType (MechanicCertificationType) VALUES 
('Standard Vehicle Mechanic License'), 
('EV Technician Certification'), 
('Refrigeration Systems Certification'), 
('Heavy Vehicle Mechanic License');