-- IMPORT THIS FILE INTO YOUR DATABASE TO CREATE THE NECESSARY TABLES AND INSERT INITIAL DATA
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
    DeliveryLeadTime SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT CHK_Supplier_DeliveryLeadTime CHECK (DeliveryLeadTime > 0)
);

CREATE TABLE Part (
    PartNumber INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    PartName VARCHAR(100) NOT NULL,
    Description TEXT NULL,
    CurrentStock SMALLINT UNSIGNED NOT NULL,
    ReorderThreshold SMALLINT UNSIGNED NOT NULL,
    UnitPrice BIGINT UNSIGNED NOT NULL,
    CONSTRAINT CHK_Part_UnitPrice CHECK (UnitPrice > 0),
    CONSTRAINT CHK_Part_ReorderThreshold CHECK (ReorderThreshold > 0)
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
    Address VARCHAR(255) NOT NULL,
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
    CONSTRAINT FK_Vehicle_Status FOREIGN KEY (OperationalStatus) REFERENCES VehicleStatus(VehicleStatusID),
    CONSTRAINT CHK_Vehicle_VIN_Length CHECK (VIN REGEXP '^[A-HJ-NPR-Z0-9]{17}$'), -- Ensures VIN is exactly 17 characters and does not contain I, O, or Q.
    CONSTRAINT CHK_Vehicle_Year CHECK (YearOfManufacture >= 1980),
    CONSTRAINT CHK_Vehicle_RegPlate CHECK (RegistrationNumber REGEXP '^[0-9]{2}[A-Z]-[0-9]{3}\\.[0-9]{2}$')
);

CREATE TABLE Driver (
    DriverID VARCHAR(20) PRIMARY KEY,
    FullName VARCHAR(255) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL,
    CurrentDepotID SMALLINT UNSIGNED NULL,
    
    -- HR / Employment Status: Tracks their relationship with the company.
    -- Replaced 'Suspended' with 'On Leave' to avoid overlap with driving suspensions.
    EmploymentStatus ENUM('Active', 'On Leave', 'Terminated') NOT NULL, 
    
    EmergencyContactDetails VARCHAR(255) NOT NULL,
    
    -- Operational Status: Tracks their privilege to operate a vehicle.
    -- 'Suspended' here specifically means they are employed but cannot drive.
    DrivingEligibility ENUM('Eligible', 'Suspended') DEFAULT 'Eligible' NOT NULL,
    
    -- Licenses and certifications will be tracked in the DriverCertification table, 
    -- allowing for multiple certifications per driver. Therefore there is no default 
    -- license type or certification field here.
    
    CONSTRAINT FK_Driver_Depot FOREIGN KEY (CurrentDepotID) REFERENCES Depot(DepotID),
    CONSTRAINT CHK_Driver_DriverID_Prefix CHECK (DriverID LIKE 'D-%')
);

CREATE TABLE Mechanic (
    MechanicID VARCHAR(20) PRIMARY KEY,
    FullName VARCHAR(255) NOT NULL,
    ContactInfo VARCHAR(255) NOT NULL,
    WorkshopID SMALLINT UNSIGNED NOT NULL,
    EmploymentStatus ENUM('Active', 'Inactive', 'Suspended', 'Terminated') NOT NULL,
    CONSTRAINT FK_Mechanic_Workshop FOREIGN KEY (WorkshopID) REFERENCES Workshop(WorkshopID),
    CONSTRAINT CHK_Mechanic_MechanicID_Prefix CHECK (MechanicID LIKE 'ME-%')
);

-- ==========================================
-- 3. Assignments, Events & Maintenance
-- ==========================================

CREATE TABLE VehicleAssignment (
    AssignmentID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    DriverID VARCHAR(20) NOT NULL,
    DepotID SMALLINT UNSIGNED NOT NULL,
    IssueDate DATETIME NOT NULL,      -- when the booking was made
    StartDate DATETIME NULL,          -- when the vehicle actually left with this driver
    EndDate DATETIME NULL,            -- when it stopped being in force (completed OR cancelled)
    AssignmentStatus ENUM('Pending', 'In Operation', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending',
    CONSTRAINT FK_VA_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_VA_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID),
    CONSTRAINT FK_VA_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID),
    CONSTRAINT CHK_VA_StatusConsistency CHECK (
        (AssignmentStatus = 'Pending'      AND StartDate IS NULL     AND EndDate IS NULL) OR
        (AssignmentStatus = 'In Operation' AND StartDate IS NOT NULL AND EndDate IS NULL
            AND StartDate >= IssueDate) OR
        (AssignmentStatus = 'Completed'    AND StartDate IS NOT NULL AND EndDate IS NOT NULL
            AND StartDate >= IssueDate AND EndDate >= StartDate) OR
        (AssignmentStatus = 'Cancelled'    AND EndDate IS NOT NULL AND EndDate >= IssueDate
            AND (StartDate IS NULL OR (StartDate >= IssueDate AND StartDate <= EndDate)))
    )
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
    CONSTRAINT FK_SE_Severity FOREIGN KEY (SeverityID) REFERENCES EventSeverity(SeverityID),
    CONSTRAINT CHK_SE_EventID_Prefix CHECK (EventID LIKE 'E%')
);

CREATE TABLE CoachingRecord ( -- No link to SafetyEvent, as coaching can be initiated for reasons other than a specific event (e.g., general performance review, proactive safety training, etc.), or it can be linked to multiple events making it impractical to link via a single field.
    CoachingRecordID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DriverID VARCHAR(20) NOT NULL,
    CoachingType ENUM('Safety Coaching', 'Retraining', 'Licence Review') NOT NULL,
    CoachingDate DATE NOT NULL,
    CompletionDate DATE NULL,
    Outcome ENUM('Passed', 'Failed', 'In Progress', 'Pending') DEFAULT 'Pending' NOT NULL,
    CONSTRAINT FK_CR_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID),
    CONSTRAINT CHK_CR_Dates CHECK (CompletionDate IS NULL OR CompletionDate >= CoachingDate),
    CONSTRAINT CHK_CR_OutcomeConsistency CHECK (
        (Outcome IN ('In Progress', 'Pending') AND CompletionDate IS NULL) OR
        (Outcome IN ('Passed', 'Failed') AND CompletionDate IS NOT NULL)
    )
);

CREATE TABLE PredictiveAlert (
    AlertID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    AlertTypeID SMALLINT UNSIGNED NOT NULL,
    DateGenerated DATETIME NOT NULL, -- The date and time when the predictive alert was generated while the vehicle was in operation, based on the predictive maintenance system's analysis of the vehicle's telemetry data.
    ActionTaken TEXT NULL,
    AlertStatus ENUM('Unresolved', 'Acknowledged', 'Scheduled For Inspection', 'Urgent Repair Standby', 'Resolved') DEFAULT 'Unresolved' NOT NULL,
    ResolutionDate DATETIME NULL,
    CONSTRAINT FK_PA_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_PA_AlertType FOREIGN KEY (AlertTypeID) REFERENCES AlertType(AlertTypeID),
    CONSTRAINT CHK_PA_ResolutionDate CHECK (ResolutionDate IS NULL OR ResolutionDate >= DateGenerated),
    CONSTRAINT CHK_PA_AlertStatusConsistency CHECK (
        (AlertStatus IN ('Unresolved', 'Acknowledged', 'Scheduled For Inspection', 'Urgent Repair Standby') AND ResolutionDate IS NULL) OR
        (AlertStatus = 'Resolved' AND ResolutionDate IS NOT NULL)
    )
);

CREATE TABLE MaintenanceJob (
    JobID VARCHAR(255) PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    WorkshopID SMALLINT UNSIGNED NOT NULL,
    ScheduleID INT UNSIGNED NULL,
    DateOpened DATETIME NOT NULL,
    DateClosed DATETIME NULL,
    Downtime DECIMAL(12,4) NOT NULL,
    TotalCost BIGINT UNSIGNED NULL,
    CONSTRAINT FK_MJ_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_MJ_Workshop FOREIGN KEY (WorkshopID) REFERENCES Workshop(WorkshopID),
    CONSTRAINT CHK_MJ_JobID_Prefix CHECK (JobID LIKE 'M%'),
    CONSTRAINT CHK_MJ_Dates CHECK (DateClosed IS NULL OR DateClosed >= DateOpened),
    CONSTRAINT CHK_MJ_Downtime CHECK (Downtime >= 0),
    CONSTRAINT CHK_MJ_ClosedHasCost CHECK (DateClosed IS NULL OR TotalCost IS NOT NULL) -- If the job is closed, there must be a total cost recorded. If the job is still open, the total cost can be NULL.
);

CREATE TABLE MaintenanceActivity (
    ActivityID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    JobID VARCHAR(255) NOT NULL,
    ActivityTypeID SMALLINT UNSIGNED NOT NULL,
    DiagnosticResult TEXT NULL,
    RepeatedFaultFlag BOOLEAN NOT NULL,
    WarrantyFlag BOOLEAN NOT NULL,
    LinkedAlertID INT UNSIGNED NULL, -- LinkAlertID is here and not in MaintenanceJob to allow multiple different activities of the same job to be linked to different alerts. If a job is created to adress multiple alerts, each activity can be linked to the specific alert it addresses.
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
    CONSTRAINT FK_DC_CertType FOREIGN KEY (DriverCertificationTypeID) REFERENCES DriverCertificationType(DriverCertificationTypeID),
    CONSTRAINT CHK_DC_Dates CHECK (ExpiryDate > IssueDate),
    CONSTRAINT CHK_DC_RevocationDate CHECK (RevocationDate IS NULL OR (RevocationDate >= IssueDate AND RevocationDate <= ExpiryDate)), -- Ensures that if a certification is revoked, the revocation date cannot be before the issue date or after the expiry date.
    CONSTRAINT CHK_DC_StatusConsistency CHECK (
        (Status = 'Active' AND RevocationDate IS NULL) OR -- Ensures that if a certification is active, it has not been revoked.
        (Status = 'Revoked' AND RevocationDate IS NOT NULL) OR -- Ensures that if a certification is revoked, there must be a revocation date.
        (Status = 'Expired') OR
        -- A certificate can be voided regardless of dates. If it is voided, it is considered invalid and ALL past operations are illegal. This is usefull for checking historical data in VehicleAssignment table, as it allows for the invalidation of all past transactions associated with a voided certificate.
        -- The revocation date can be set to either NULL or a valid date in this case, as the voiding of the certificate is independent of the revocation process, meaning it can be revoked and then be voided, or it can be voided without being revoked.
        (Status = 'Voided') OR
        (Status = 'Reinstated' AND RevocationDate IS NOT NULL) -- Ensures that if a certification is reinstated, it must have been revoked.
    ) -- Ensures that the status of the certification is consistent with the dates provided.
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
    CONSTRAINT FK_MC_CertType FOREIGN KEY (MechanicCertificationTypeID) REFERENCES MechanicCertificationType(MechanicCertificationTypeID),
    CONSTRAINT CHK_MC_Dates CHECK (ExpiryDate > IssueDate),
    CONSTRAINT CHK_MC_RevocationDate CHECK (RevocationDate IS NULL OR (RevocationDate >= IssueDate AND RevocationDate IS NOT NULL AND RevocationDate <= ExpiryDate)),
    CONSTRAINT CHK_MC_StatusConsistency CHECK (
        (Status = 'Active' AND RevocationDate IS NULL ) OR
        (Status = 'Revoked' AND RevocationDate IS NOT NULL) OR
        (Status = 'Expired') OR
        (Status = 'Voided') OR
        (Status = 'Reinstated' AND RevocationDate IS NOT NULL)
    )
);

CREATE TABLE EventReview (
    ReviewID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    EventID VARCHAR(100) NOT NULL,
    ReviewerStaffID MEDIUMINT UNSIGNED NOT NULL,
    Comments TEXT NULL,
    Recommendations TEXT NULL,
    Status ENUM('Unread', 'Read', 'Commented', 'Closed') DEFAULT 'Unread' NOT NULL,
    DateReviewed DATETIME NULL,
    CONSTRAINT FK_ER_Event FOREIGN KEY (EventID) REFERENCES SafetyEvent(EventID),
    CONSTRAINT FK_ER_Staff FOREIGN KEY (ReviewerStaffID) REFERENCES SafetyStaff(ReviewStaffID),
    CONSTRAINT CHK_ER_StatusConsistency CHECK (
        (Status = 'Unread' AND DateReviewed IS NULL) OR
        (Status = 'Read' AND DateReviewed IS NOT NULL) OR
        (Status = 'Commented' AND DateReviewed IS NOT NULL AND Comments IS NOT NULL) OR
        (Status = 'Closed' AND DateReviewed IS NOT NULL) -- Can't be edited after being closed, but can be closed without comments if the reviewer deems it unnecessary (dismissed, no action required, etc.). The review can be closed without comments, but it cannot be closed without being read first. Will be imlemented via a TRIGGER.
    )
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
    CONSTRAINT FK_PR_Severity FOREIGN KEY (SeverityID) REFERENCES EventSeverity(SeverityID),
    CONSTRAINT CHK_PR_PenaltyPoints CHECK (PenaltyPoints >= 0),
    CONSTRAINT CHK_PR_MinEventCount CHECK (MinEventCount > 0),
    CONSTRAINT CHK_PR_TimeWindowMonths CHECK (TimeWindowMonths > 0),
    CONSTRAINT CHK_PR_Target_Consistency CHECK (EventTypeID IS NOT NULL OR SeverityID IS NOT NULL) -- See edge cases in SEED DATA section at 11. PenaltyRule.
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
    CONSTRAINT FK_DMSS_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID),
    CONSTRAINT CHK_DMSS_Month CHECK (Month BETWEEN 1 AND 12),
    CONSTRAINT CHK_DMSS_Score CHECK (Score <= 100) -- The score can be negative due to penalties, but it cannot exceed 100.
);

CREATE TABLE DriverScorePenalty (
    ScorePenaltyID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    DriverMonthlySafetyScoreID INT UNSIGNED NOT NULL,
    PenaltyRuleID SMALLINT UNSIGNED NOT NULL,
    EventID VARCHAR(100) NOT NULL, -- For linking to what event it was regardless whether PenaltyRuleID has EventTypeID or not. This allows for the tracking of penalties applied to specific events, even if the penalty rule is not directly tied to an event type.
    PointsDeducted DECIMAL(5,2) NOT NULL,
    DateApplied DATETIME NOT NULL,
    CONSTRAINT FK_DSP_Score FOREIGN KEY (DriverMonthlySafetyScoreID) REFERENCES DriverMonthlySafetyScore(DriverMonthlySafetyScoreID),
    CONSTRAINT FK_DSP_Rule FOREIGN KEY (PenaltyRuleID) REFERENCES PenaltyRule(PenaltyRuleID),
    CONSTRAINT FK_DSP_Event FOREIGN KEY (EventID) REFERENCES SafetyEvent(EventID),
    CONSTRAINT CHK_DSP_PointsDeducted CHECK (PointsDeducted > 0)
);

CREATE TABLE ScheduledService (
    ScheduleID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    VIN VARCHAR(17) NOT NULL,
    ScheduledDate DATE NOT NULL,
    Reason TEXT NULL,
    AlertID INT UNSIGNED NULL,
    CompletionDate DATE NULL,
    Status ENUM('Scheduled', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Scheduled' NOT NULL,
    CONSTRAINT FK_SS_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN),
    CONSTRAINT FK_SS_Alert FOREIGN KEY (AlertID) REFERENCES PredictiveAlert(AlertID),
    CONSTRAINT CHK_SS_CompletionDate CHECK (CompletionDate IS NULL OR CompletionDate >= ScheduledDate),
    CONSTRAINT CHK_SS_StatusConsistency CHECK (
        (Status IN ('Scheduled', 'In Progress') AND CompletionDate IS NULL) OR
        (Status = 'Completed' AND CompletionDate IS NOT NULL) OR
        (Status = 'Cancelled' AND CompletionDate IS NULL)
    )
);

ALTER TABLE MaintenanceJob
ADD CONSTRAINT FK_MJ_Schedule FOREIGN KEY (ScheduleID) REFERENCES ScheduledService(ScheduleID);

-- ==========================================
-- 6. Workshop Operations & Parts Tracking
-- ==========================================

CREATE TABLE MechanicWorkSession (
    SessionID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MechanicID VARCHAR(20) NOT NULL,
    ActivityID INT UNSIGNED NOT NULL,
    StartTime DATETIME NOT NULL,
    EndTime DATETIME NULL,
    -- A mechanic can have multiple work sessions for a single activity (e.g., different shifts, different days, taking breaks, etc.), and the total labour hours for that activity can be derived from the sum of all work sessions.
    CONSTRAINT FK_MWS_Mechanic FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID),
    CONSTRAINT FK_MWS_Activity FOREIGN KEY (ActivityID) REFERENCES MaintenanceActivity(ActivityID),
    CONSTRAINT CHK_MWS_Times CHECK (EndTime IS NULL OR EndTime >= StartTime)
);

CREATE TABLE WarrantyClaim (
    ClaimID INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ActivityID INT UNSIGNED NOT NULL,
    ClaimSource ENUM('Vehicle Manufacturer', 'Parts Supplier', 'Internal Claim') NOT NULL,
    ClaimDate DATE NOT NULL,
    Status ENUM('Pending', 'Approved', 'Rejected', 'Settled') DEFAULT 'Pending' NOT NULL,
    CONSTRAINT FK_WC_Activity FOREIGN KEY (ActivityID) REFERENCES MaintenanceActivity(ActivityID),
    ResolutionDate DATE NULL,
    CONSTRAINT CHK_WC_ResolutionDate CHECK (
        ResolutionDate IS NULL OR ResolutionDate >= ClaimDate),
    CONSTRAINT CHK_WC_StatusConsistency CHECK (
        (Status = 'Pending' AND ResolutionDate IS NULL) OR
        (Status IN ('Approved', 'Rejected', 'Settled') AND ResolutionDate IS NOT NULL)
)
);

CREATE TABLE PartSupplier (
    PartNumber INT UNSIGNED,
    SupplierID SMALLINT UNSIGNED,
    IsPrimary BOOLEAN NOT NULL,
    UnitCost BIGINT UNSIGNED NOT NULL,
    -- NULL whenever IsPrimary = FALSE, and PartNumber itself whenever
    -- IsPrimary = TRUE. UNIQUE on this column then only restricts the
    -- primary rows (MySQL allows unlimited NULLs in a UNIQUE index), so
    -- exactly one primary supplier per part is still enforced while backup
    -- suppliers are unrestricted in count.
    PrimaryPartNumber INT UNSIGNED GENERATED ALWAYS AS (IF(IsPrimary, PartNumber, NULL)) VIRTUAL,
    PRIMARY KEY (PartNumber, SupplierID),
    CONSTRAINT UC_PS_OnePrimaryPerPart UNIQUE (PrimaryPartNumber), -- Ensures at most one primary supplier per part; backup suppliers (IsPrimary = FALSE) are not limited in count.
    CONSTRAINT FK_PS_Part FOREIGN KEY (PartNumber) REFERENCES Part(PartNumber),
    CONSTRAINT FK_PS_Supplier FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID),
    CONSTRAINT CHK_PS_UnitCost CHECK (UnitCost > 0)
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
    CONSTRAINT FK_AP_Claim FOREIGN KEY (ClaimID) REFERENCES WarrantyClaim(ClaimID),
    CONSTRAINT CHK_AP_QuantityUsed CHECK (QuantityUsed > 0),
    CONSTRAINT CHK_AP_UnitCost CHECK (UnitCost > 0)
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

-- 8. MechanicCertificationType
INSERT INTO MechanicCertificationType (MechanicCertificationType) VALUES 
('Standard Vehicle Mechanic License'), 
('EV Technician Certification'), 
('Refrigeration Systems Certification'), 
('Heavy Vehicle Mechanic License');

-- 9. ActivityType
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

-- 10. VehicleCertificationRequirement
INSERT INTO VehicleCertificationRequirement (VehicleCategoryID, DriverCertificationTypeID) VALUES
(1, 1), -- Delivery Van requires Standard License
(2, 1), -- Refrigerated Truck requires Standard License
(2, 2), -- Refrigerated Truck also requires Heavy Vehicle License
(2, 3), -- Refrigerated Truck also requires Refrigerated Transport Certification
(3, 1), -- Electric Van requires Standard License
(3, 4), -- Electric Van also requires EV Certification
(4, 1), -- Service Vehicle requires Standard License
(5, 2), -- Heavy Transport Truck requires Heavy Vehicle License
(5, 5); -- Heavy Transport Truck also requires Hazardous Goods Certification

-- 11. PenaltyRule
INSERT INTO PenaltyRule (RuleType, RuleDescription, EventTypeID, SeverityID, MinEventCount, TimeWindowMonths, PenaltyPoints) VALUES
('Base', 'Base penalty for Low severity events', NULL, 1, 1, 1, 2.0),
('Base', 'Base penalty for Medium severity events', NULL, 2, 1, 1, 5.0),
('Base', 'Base penalty for High severity events', NULL, 3, 1, 1, 10.0),
('Base', 'Base penalty for Critical severity events', NULL, 4, 1, 1, 20.0),
('Conditional', 'Conditional penalty for more than 3 speeding events within a month', 3, NULL, 3, 1, 10.0),
('Conditional', 'Conditional penalty for more than 2 fatigue warnings within a month', 6, NULL, 2, 1, 15.0);

-- Edge case penalties can be added as needed, for example:
-- ('Base', 'Base penalty for Excessive speeding events', 3, NULL, 1, 1, 1.0),
-- ('Conditional', 'Conditional penalty for more than 3 Medium severity events within 2 month', NULL, 2, 3, 2, 10.0)

-- ==========================================================
-- VEHICLE ASSIGNMENT TRIGGERS  (1 of 5)
-- ==========================================================
-- Scope: fn_NextVehicleStatus (the shared vehicle-status derivation
-- function) and the full VehicleAssignment lifecycle -- booking
-- (Pending) -> In Operation -> Completed/Cancelled -- including the
-- eligibility/certification gate and the vehicle status flips that
-- go with each transition.
--
-- Depends on: schema.sql
-- Note: fn_NextVehicleStatus, defined below, is also called from the
-- MaintenanceJob triggers in maintenance_and_alert_triggers.sql.
-- ==========================================================

-- ==========================================
-- SUPPORTING FUNCTION
-- ==========================================
-- Decides what a vehicle should become when it's released back to the fleet,
-- whether that's from a VehicleAssignment ending or a MaintenanceJob closing.
-- Checks three independent sources of truth, in priority order: is another
-- MaintenanceJob still open on this VIN, is there still an In Operation
-- VehicleAssignment on it, and finally, is a ScheduledService due. Extracted
-- because every call site needs the same full picture, and duplicating this
-- logic across triggers was already a maintenance risk with just two call
-- sites -- now with three checks instead of one, keeping it in one place
-- matters even more.

DELIMITER //

CREATE FUNCTION fn_NextVehicleStatus(p_VIN VARCHAR(17))
RETURNS SMALLINT UNSIGNED
NOT DETERMINISTIC -- The result can change over time as the vehicle's state changes (new jobs, assignments, or services).
READS SQL DATA
BEGIN
    -- Declare variables to hold counts and status ID
    DECLARE v_OpenJobs INT DEFAULT 0;
    DECLARE v_OpenAssignment INT DEFAULT 0;
    DECLARE v_PendingServices INT DEFAULT 0;
    DECLARE v_StatusID SMALLINT UNSIGNED;

    -- Tier 1: still physically being worked on (another job open on this VIN)?
    -- Beats everything else -- a vehicle mid-repair can't be handed to a driver.
    SELECT COUNT(*) INTO v_OpenJobs
    FROM MaintenanceJob
    WHERE VIN = p_VIN AND DateClosed IS NULL; -- Check for open maintenance jobs

    IF v_OpenJobs > 0 THEN
        SELECT VehicleStatusID INTO v_StatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Under Maintenance';
        RETURN v_StatusID;
    END IF;

    -- Tier 2: still administratively out with a driver? (The "emergency
    -- repair on an In Operation vehicle" case -- we don't auto-cancel that
    -- assignment, so when the job closes it should go back to Active, not
    -- Available, since someone still has it.)
    SELECT COUNT(*) INTO v_OpenAssignment
    FROM VehicleAssignment
    WHERE VIN = p_VIN AND AssignmentStatus = 'In Operation';

    IF v_OpenAssignment > 0 THEN
        SELECT VehicleStatusID INTO v_StatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Active';
        RETURN v_StatusID;
    END IF;

    -- Tier 3: free and clear -- just check whether something's due.
    SELECT COUNT(*) INTO v_PendingServices
    FROM ScheduledService
    WHERE VIN = p_VIN
      AND Status IN ('Scheduled', 'In Progress')
      AND ScheduledDate <= CURDATE();

    IF v_PendingServices > 0 THEN
        SELECT VehicleStatusID INTO v_StatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Awaiting Inspection';
    ELSE
        SELECT VehicleStatusID INTO v_StatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Available';
    END IF;

    RETURN v_StatusID;
END;
//

DELIMITER ;



-- ==========================================
-- TRIGGERS: Vehicle Assignment Validations & Status Automation
-- ==========================================

DELIMITER //

-- 1. BEFORE INSERT: Gate only applies when a row is born already 'In Operation'
--    (walk-up assignment, no advance Pending booking). 'Pending' inserts skip
--    validation entirely -- that's the whole point of Pending existing.
--
--    Historical backfills landing directly as Completed/Cancelled also skip
--    the gate, since checking today's vehicle/driver state against a past
--    record would reject perfectly legitimate historical data.
CREATE TRIGGER TRG_VehicleAssignment_BeforeInsert
BEFORE INSERT ON VehicleAssignment
FOR EACH ROW
BEGIN
    DECLARE v_VehicleStatus VARCHAR(100);
    DECLARE v_DriverEligibility VARCHAR(100);
    DECLARE v_EmploymentStatus VARCHAR(50);
    DECLARE v_CategoryID SMALLINT UNSIGNED;
    DECLARE v_MissingCerts INT DEFAULT 0;

    IF NEW.AssignmentStatus = 'In Operation' THEN

        SELECT vs.VehicleStatus, v.CategoryID
        INTO v_VehicleStatus, v_CategoryID
        FROM Vehicle v
        JOIN VehicleStatus vs ON v.OperationalStatus = vs.VehicleStatusID
        WHERE v.VIN = NEW.VIN;

        IF v_VehicleStatus IS NULL OR v_VehicleStatus <> 'Available' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot assign vehicle: vehicle is not currently Available.';
        END IF;

        SELECT DrivingEligibility, EmploymentStatus
        INTO v_DriverEligibility, v_EmploymentStatus
        FROM Driver
        WHERE DriverID = NEW.DriverID;

        -- Two independent axes: EmploymentStatus (do they
        -- work here right now) and DrivingEligibility (are they cleared to
        -- drive). Both must pass -- a fully eligible driver who's On Leave or
        -- Terminated is still not assignable.
        IF v_EmploymentStatus IS NULL OR v_EmploymentStatus <> 'Active' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot assign driver: driver is not currently an active employee.';
        END IF;

        IF v_DriverEligibility <> 'Eligible' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot assign driver: driver is not currently eligible.';
        END IF;

        SELECT COUNT(*) INTO v_MissingCerts
        FROM VehicleCertificationRequirement vcr
        WHERE vcr.VehicleCategoryID = v_CategoryID
          AND NOT EXISTS (
              SELECT 1 FROM DriverCertification dc
              WHERE dc.DriverID = NEW.DriverID
                AND dc.DriverCertificationTypeID = vcr.DriverCertificationTypeID
                AND dc.Status IN ('Active', 'Reinstated')
                AND dc.ExpiryDate > CURDATE()
          );

        IF v_MissingCerts > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot assign driver: driver lacks required active certifications for this vehicle category.';
        END IF;

    END IF;
END;
//


-- 2. BEFORE UPDATE: Transition guard + field-lock + gate on the one transition
--    that actually starts an assignment.
CREATE TRIGGER TRG_VehicleAssignment_BeforeUpdate
BEFORE UPDATE ON VehicleAssignment
FOR EACH ROW
BEGIN
    DECLARE v_VehicleStatus VARCHAR(100);
    DECLARE v_DriverEligibility VARCHAR(100);
    DECLARE v_EmploymentStatus VARCHAR(50);
    DECLARE v_CategoryID SMALLINT UNSIGNED;
    DECLARE v_MissingCerts INT DEFAULT 0;

    -- Rule 0: Completed/Cancelled are terminal. Nothing about the row moves again.
    IF OLD.AssignmentStatus IN ('Completed', 'Cancelled') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify a Completed or Cancelled assignment.';
    END IF;

    -- Rule 1: Only these status transitions are legal.
    IF OLD.AssignmentStatus <> NEW.AssignmentStatus THEN
        IF NOT (
            (OLD.AssignmentStatus = 'Pending'      AND NEW.AssignmentStatus IN ('In Operation', 'Cancelled'))
            OR (OLD.AssignmentStatus = 'In Operation' AND NEW.AssignmentStatus IN ('Completed', 'Cancelled'))
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid assignment status transition.';
        END IF;
    END IF;

    -- Rule 2: Once an assignment has left Pending, the facts of "who/what/when
    -- it started" are locked. Only Pending rows are freely correctable.
    IF OLD.AssignmentStatus <> 'Pending' THEN
        IF NEW.VIN <> OLD.VIN
           OR NEW.DriverID <> OLD.DriverID
           OR NEW.DepotID <> OLD.DepotID
           OR NEW.IssueDate <> OLD.IssueDate
           OR NOT (NEW.StartDate <=> OLD.StartDate) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot modify VIN, DriverID, DepotID, IssueDate, or StartDate once an assignment has left Pending.';
        END IF;
    END IF;

    -- Rule 3: Re-run the full gate on the Pending -> In Operation transition,
    -- since time has passed since the booking was made (cert could've expired,
    -- vehicle could've gone into maintenance, driver could've been suspended).
    IF OLD.AssignmentStatus = 'Pending' AND NEW.AssignmentStatus = 'In Operation' THEN

        IF NEW.StartDate IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'StartDate must be set when transitioning to In Operation.';
        END IF;

        SELECT vs.VehicleStatus, v.CategoryID
        INTO v_VehicleStatus, v_CategoryID
        FROM Vehicle v
        JOIN VehicleStatus vs ON v.OperationalStatus = vs.VehicleStatusID
        WHERE v.VIN = NEW.VIN;

        IF v_VehicleStatus IS NULL OR v_VehicleStatus <> 'Available' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot start assignment: vehicle is not currently Available.';
        END IF;

        SELECT DrivingEligibility, EmploymentStatus
        INTO v_DriverEligibility, v_EmploymentStatus
        FROM Driver
        WHERE DriverID = NEW.DriverID;

        IF v_EmploymentStatus IS NULL OR v_EmploymentStatus <> 'Active' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot start assignment: driver is not currently an active employee.';
        END IF;

        IF v_DriverEligibility <> 'Eligible' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot start assignment: driver is not currently eligible.';
        END IF;

        SELECT COUNT(*) INTO v_MissingCerts
        FROM VehicleCertificationRequirement vcr
        WHERE vcr.VehicleCategoryID = v_CategoryID
          AND NOT EXISTS (
              SELECT 1 FROM DriverCertification dc
              WHERE dc.DriverID = NEW.DriverID
                AND dc.DriverCertificationTypeID = vcr.DriverCertificationTypeID
                AND dc.Status IN ('Active', 'Reinstated')
                AND dc.ExpiryDate > CURDATE()
          );

        IF v_MissingCerts > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot start assignment: driver lacks required active certifications.';
        END IF;

    END IF;

END;
//


-- 3. AFTER INSERT: Only fires the vehicle over to 'Active' when a row is born
--    directly 'In Operation' (the walk-up case). A 'Pending' insert doesn't
--    touch the vehicle at all -- nothing has physically happened yet.
CREATE TRIGGER TRG_VehicleAssignment_AfterInsert
AFTER INSERT ON VehicleAssignment
FOR EACH ROW
BEGIN
    DECLARE v_ActiveStatusID SMALLINT UNSIGNED;

    IF NEW.AssignmentStatus = 'In Operation' THEN
        SELECT VehicleStatusID INTO v_ActiveStatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Active';

        UPDATE Vehicle
        SET OperationalStatus = v_ActiveStatusID
        WHERE VIN = NEW.VIN;
    END IF;
END;
//


-- 4. AFTER UPDATE: Two independent triggers for the vehicle, matching the two
--    points in the lifecycle where the vehicle's real-world state changes.
CREATE TRIGGER TRG_VehicleAssignment_AfterUpdate
AFTER UPDATE ON VehicleAssignment
FOR EACH ROW
BEGIN
    DECLARE v_ActiveStatusID SMALLINT UNSIGNED;

    -- Booking just went live (Pending -> In Operation): vehicle leaves the depot.
    IF OLD.AssignmentStatus = 'Pending' AND NEW.AssignmentStatus = 'In Operation' THEN
        SELECT VehicleStatusID INTO v_ActiveStatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Active';

        UPDATE Vehicle
        SET OperationalStatus = v_ActiveStatusID
        WHERE VIN = NEW.VIN;
    END IF;

    -- Vehicle physically comes back, whether the run finished or was aborted
    -- mid-route. Either way it needs to be re-triaged for the next state.
    IF OLD.AssignmentStatus = 'In Operation' AND NEW.AssignmentStatus IN ('Completed', 'Cancelled') THEN
        UPDATE Vehicle
        SET OperationalStatus = fn_NextVehicleStatus(NEW.VIN) -- See fn_NextVehicleStatus at line 30 in 1.vehicle_assignment_functions.sql for the full triage logic.
        WHERE VIN = NEW.VIN;
    END IF;

    -- Pending -> Cancelled: the vehicle was never touched by this booking
    -- (no gate ran, no status flip happened on insert), so there's nothing
    -- to release here. Intentionally a no-op.

END;
//

DELIMITER ;

-- ==========================================================
-- MAINTENANCE & PREDICTIVE ALERT TRIGGERS  (2 of 5)
-- ==========================================================
-- Scope: MaintenanceJob lifecycle automation (open/close, the
-- one-open-job-per-VIN gate, the historical-fact lock) and the
-- PredictiveAlert -> ScheduledService auto-scheduling procedure
-- and triggers.
--
-- Depends on: schema.sql, vehicle_assignment_triggers.sql
-- (calls fn_NextVehicleStatus, defined there).
-- ==========================================================

-- ==========================================
-- TRIGGERS: Maintenance Job Lifecycle Automation
-- ==========================================
-- Refactored to call fn_NextVehicleStatus instead of duplicating the
-- "check ScheduledService" logic that used to live in both this trigger
-- and TRG_VehicleAssignment_AfterUpdate.

DELIMITER //

-- 0. BEFORE INSERT: A vehicle can only be in one workshop bay at a time --
--    reject a new job if one's already open on this VIN. This is the
--    root-cause fix for the overlapping-jobs issue; the fn_NextVehicleStatus
--    rewrite below is the defense-in-depth backstop in case this is ever
--    bypassed (bulk import, race condition, etc.).
CREATE TRIGGER TRG_MaintenanceJob_BeforeInsert
BEFORE INSERT ON MaintenanceJob
FOR EACH ROW
BEGIN
    DECLARE v_OpenJobs INT DEFAULT 0;

    SELECT COUNT(*) INTO v_OpenJobs
    FROM MaintenanceJob
    WHERE VIN = NEW.VIN AND DateClosed IS NULL;

    IF v_OpenJobs > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot open a new maintenance job: this vehicle already has an open job.';
    END IF;
END;
//

-- 0.5 BEFORE UPDATE: Same "historical fact once written" lock as every other
--     record-of-a-thing-that-happened table in this project. VIN, WorkshopID,
--     DateOpened, and ScheduleID are locked. DateClosed and TotalCost stay
--     open (closing/costing the job is the whole point) -- EXCEPT DateClosed
--     can never move back from NOT NULL to NULL. NOTE: Un-closing a job would
--     silently break the one-open-job-per-VIN gate above, since that gate
--     only runs on INSERT: Job A closes, Job B opens (allowed, A is closed),
--     then un-closing A would leave two jobs open on the same VIN with
--     nothing left to catch it.
CREATE TRIGGER TRG_MaintenanceJob_BeforeUpdate
BEFORE UPDATE ON MaintenanceJob
FOR EACH ROW
BEGIN
    IF NEW.VIN <> OLD.VIN
       OR NEW.WorkshopID <> OLD.WorkshopID
       OR NEW.DateOpened <> OLD.DateOpened
       OR NOT (NEW.ScheduleID <=> OLD.ScheduleID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify VIN, WorkshopID, DateOpened, or ScheduleID on an existing maintenance job.';
    END IF;

    IF OLD.DateClosed IS NOT NULL AND NEW.DateClosed IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot re-open a maintenance job that has already been closed.';
    END IF;
END;
//

-- 1. AFTER INSERT: Force vehicle into 'Under Maintenance' the second a job opens,
--    regardless of what it was doing before (Available, Awaiting Inspection, or
--    still administratively 'In Operation' under an unrelated active assignment --
--    per our discussion, we're deliberately NOT auto-cancelling that assignment).
--
--    FIX (found during seed-data generator design): the original version of
--    this trigger set 'Under Maintenance' unconditionally, with no check on
--    NEW.DateClosed.
--
--    A job inserted already-closed (e.g. a historical backfill row)
--    would still shove the vehicle into 'Under Maintenance' --
--    but since TRG_MaintenanceJob_AfterUpdate's release logic only fires on
--    an actual OLD.DateClosed IS NULL -> NEW.DateClosed IS NOT NULL
--    transition, a pre-closed insert leaves nothing to ever release it, and
--    a linked ScheduledService (if any) never gets its back-write either.
--    
--    Branching on NEW.DateClosed here mirrors the AfterUpdate logic for the
--    already-closed case, so both entry points (insert-open-then-update, and
--    insert-pre-closed-in-one-shot) leave the vehicle and any linked
--    ScheduledService correctly triaged.
CREATE TRIGGER TRG_MaintenanceJob_AfterInsert
AFTER INSERT ON MaintenanceJob
FOR EACH ROW
BEGIN
    DECLARE v_UnderMaintenanceStatusID SMALLINT UNSIGNED;

    IF NEW.DateClosed IS NULL THEN
        -- Job is genuinely open: vehicle goes into the shop now.
        SELECT VehicleStatusID INTO v_UnderMaintenanceStatusID
        FROM VehicleStatus WHERE VehicleStatus = 'Under Maintenance';

        UPDATE Vehicle
        SET OperationalStatus = v_UnderMaintenanceStatusID
        WHERE VIN = NEW.VIN;
    ELSE
        -- Job arrived already closed (e.g. historical backfill): it never
        -- actually held the vehicle at insert time, so re-triage instead of
        -- forcing Under Maintenance. Mirrors the AfterUpdate release path.
        IF NEW.ScheduleID IS NOT NULL THEN
            UPDATE ScheduledService
            SET Status = 'Completed',
                CompletionDate = DATE(NEW.DateClosed)
            WHERE ScheduleID = NEW.ScheduleID;
        END IF;

        UPDATE Vehicle
        SET OperationalStatus = fn_NextVehicleStatus(NEW.VIN) -- See fn_NextVehicleStatus at line 30 in 1.vehicle_assignment_functions.sql for the full triage logic.
        WHERE VIN = NEW.VIN;
    END IF;
END;
//


-- 2. AFTER UPDATE: Release vehicle when the job closes. Also back-writes the
--    linked ScheduledService to Completed, if this job was fulfilling one --
--    otherwise that service sits at 'Scheduled' forever, permanently overdue,
--    and fn_NextVehicleStatus would keep routing this vehicle to
--    'Awaiting Inspection' even after the work that satisfied it is done.
CREATE TRIGGER TRG_MaintenanceJob_AfterUpdate
AFTER UPDATE ON MaintenanceJob
FOR EACH ROW
BEGIN
    IF OLD.DateClosed IS NULL AND NEW.DateClosed IS NOT NULL THEN

        IF NEW.ScheduleID IS NOT NULL THEN
            UPDATE ScheduledService
            SET Status = 'Completed',
                CompletionDate = DATE(NEW.DateClosed)
            WHERE ScheduleID = NEW.ScheduleID;
        END IF;

        UPDATE Vehicle
        SET OperationalStatus = fn_NextVehicleStatus(NEW.VIN) -- See fn_NextVehicleStatus at line 30 in 1.vehicle_assignment_functions.sql for the full triage logic.
        WHERE VIN = NEW.VIN;
    END IF;
END;
//

DELIMITER ;


-- ==========================================
-- SUPPORTING PROCEDURE + TRIGGERS: Predictive Alert Auto-Scheduling
-- ==========================================
-- When staff escalate a PredictiveAlert to 'Scheduled For Inspection' or
-- 'Urgent Repair Standby', a ScheduledService row gets created automatically
-- -- but NOT for the raw 'Unresolved' telemetry signal itself, since that
-- would auto-schedule every blip before a human's looked at it. Two entry
-- points (insert directly at an escalated status, or update into one) share
-- one procedure so the guard logic only exists in one place.

DELIMITER //

CREATE PROCEDURE sp_AutoScheduleFromAlert(IN p_AlertID INT UNSIGNED, IN p_VIN VARCHAR(17))
BEGIN
    DECLARE v_Existing INT DEFAULT 0;

    -- Guard against re-triggering a duplicate schedule if the alert bounces
    -- between statuses again while one's already open.
    SELECT COUNT(*) INTO v_Existing
    FROM ScheduledService
    WHERE AlertID = p_AlertID AND Status IN ('Scheduled', 'In Progress');

    IF v_Existing = 0 THEN
        INSERT INTO ScheduledService (VIN, ScheduledDate, Reason, AlertID, Status)
        VALUES (
            p_VIN,
            CURDATE(),
            CONCAT('Auto-generated from PredictiveAlert #', p_AlertID),
            p_AlertID,
            'Scheduled'
        );
    END IF;
END;
//

-- Trigger to automatically schedule maintenance/inspection when an escalated predictive alert is created
CREATE TRIGGER TRG_PredictiveAlert_AfterInsert
AFTER INSERT ON PredictiveAlert
FOR EACH ROW
BEGIN
    IF NEW.AlertStatus IN ('Scheduled For Inspection', 'Urgent Repair Standby') THEN
        CALL sp_AutoScheduleFromAlert(NEW.AlertID, NEW.VIN); -- See sp_AutoScheduleFromAlert at line 165 in 2.maintenance_and_alert_triggers.sql for the full guard logic.
    END IF;
END;
//


-- Trigger to automatically schedule maintenance/inspection when a predictive alert is escalated/updated to an escalated status
CREATE TRIGGER TRG_PredictiveAlert_AfterUpdate
AFTER UPDATE ON PredictiveAlert
FOR EACH ROW
BEGIN
    IF NEW.AlertStatus IN ('Scheduled For Inspection', 'Urgent Repair Standby')
       AND OLD.AlertStatus <> NEW.AlertStatus THEN
        CALL sp_AutoScheduleFromAlert(NEW.AlertID, NEW.VIN); -- See sp_AutoScheduleFromAlert at line 165 in 2.maintenance_and_alert_triggers.sql for the full guard logic.
    END IF;
END;
//

DELIMITER ;

-- ==========================================================
-- DRIVER ELIGIBILITY & SAFETY EVENT TRIGGERS  (3 of 5)
-- ==========================================================
-- Scope: sp_RecomputeDriverEligibility (the cached-eligibility
-- engine) and everything that happens on SafetyEvent creation --
-- severity routing, the eligibility recompute for Critical events,
-- penalty rule evaluation against DriverScorePenalty, and the
-- historical-fact lock on SafetyEvent itself.
--
-- Depends on: schema.sql
-- Note: sp_RecomputeDriverEligibility, defined below, is also called
-- from review_coaching_and_scoring_triggers.sql (EventReview and
-- CoachingRecord triggers) whenever a blocking reason clears.
-- ==========================================================

-- ==========================================
-- SHARED PROCEDURE: Driver Eligibility Recompute
-- ==========================================
-- DrivingEligibility is a CACHE, not a record. Nothing ever writes 'Eligible'
-- or 'Suspended' from local knowledge -- every touchpoint (critical event,
-- review closing, coaching outcome) calls this, and it re-derives the answer
-- from scratch by checking every disqualifying condition. This is what lets
-- two independent reasons (an open review AND an open retraining) coexist
-- without one trigger clobbering the other's write.
--
-- DELIBERATE DESIGN DECISION: a driver is only Eligible again once EVERY
-- open reason clears (AND-to-clear), not once ANY single reason clears. The
-- brief's "until the review has been completed or he completes the safety
-- training" describes the two release valves the system has, not a strict
-- either/or on one shared block. Reason 1 (critical event review) and
-- Reason 2 (score-driven retraining) have different causes and don't know
-- about each other -- a driver whose critical-event review just closed but
-- who separately has an open retraining from a bad score stays Suspended,
-- because the retraining is what's actually making them unsafe to drive,
-- and it's unrelated to whether that specific review happened to finish.

DELIMITER //

CREATE PROCEDURE sp_RecomputeDriverEligibility(IN p_DriverID VARCHAR(20))
BEGIN
    DECLARE v_Blocked BOOLEAN DEFAULT FALSE;

    -- Reason 1: an unresolved Critical-severity event. SafetyEvent.ReviewState
    -- is itself kept in sync with EventReview by the triggers below, so this
    -- only reads a column, it doesn't re-derive review state itself.
    IF EXISTS (
        SELECT 1
        FROM SafetyEvent se
        JOIN EventSeverity sev ON sev.SeverityID = se.SeverityID
        WHERE se.DriverID = p_DriverID
          AND sev.SeverityLevel = 'Critical'
          AND se.ReviewState <> 'Completed'
    ) THEN
        SET v_Blocked = TRUE;
    END IF;

    -- Reason 2: an outstanding Retraining requirement (score <= 50 cascade).
    -- Anything other than 'Passed' keeps the driver blocked, including 'Failed'.
    -- A failed retraining doesn't clear the requirement, it just sits there
    -- until staff enrol them in a new one or update the outcome.
    IF EXISTS (
        SELECT 1
        FROM CoachingRecord
        WHERE DriverID = p_DriverID
          AND CoachingType = 'Retraining'
          AND Outcome <> 'Passed'
    ) THEN
        SET v_Blocked = TRUE;
    END IF;

    -- This is the ONLY authorized writer of DrivingEligibility -- the flag
    -- tells TRG_Driver_BeforeUpdate to let this specific write through, and
    -- gets cleared immediately after so nothing else can piggyback on it.
    SET @sfms_allow_eligibility_write = 1; -- Allow direct write to DrivingEligibility
    UPDATE Driver
    SET DrivingEligibility = IF(v_Blocked, 'Suspended', 'Eligible')
    WHERE DriverID = p_DriverID;
    SET @sfms_allow_eligibility_write = NULL; -- Clear the flag so no other writes can sneak through
END;
//


-- BEFORE UPDATE: DrivingEligibility is derived-only. Any attempt to write it
-- outside of sp_RecomputeDriverEligibility (i.e. without the flag set) is
-- rejected -- this is what makes the "cache, not a record" design an actual
-- enforced invariant rather than just a comment everyone has to remember to
-- respect.
CREATE TRIGGER TRG_Driver_BeforeUpdate
BEFORE UPDATE ON Driver
FOR EACH ROW
BEGIN
    IF NEW.DrivingEligibility <> OLD.DrivingEligibility
       AND (@sfms_allow_eligibility_write IS NULL OR @sfms_allow_eligibility_write <> 1) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DrivingEligibility cannot be written directly; it is derived by sp_RecomputeDriverEligibility. Please check for open critical events or outstanding retraining requirements.';
    END IF;
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGERS: SafetyEvent - Severity Routing
-- ==========================================

DELIMITER //

-- BEFORE INSERT: High/Critical always forces 'Pending', overriding whatever
-- the app sent. Low/Medium is left completely alone -- if the app didn't
-- specify a value, the column's own DEFAULT 'No Review Required' already
-- applies before this trigger runs, so there's nothing extra to do here.
CREATE TRIGGER TRG_SafetyEvent_BeforeInsert
BEFORE INSERT ON SafetyEvent
FOR EACH ROW
BEGIN
    DECLARE v_SeverityLevel VARCHAR(100);

    SELECT SeverityLevel INTO v_SeverityLevel
    FROM EventSeverity WHERE SeverityID = NEW.SeverityID;

    IF v_SeverityLevel IN ('High', 'Critical') THEN
        SET NEW.ReviewState = 'Pending';
    END IF;
END;
//

-- AFTER INSERT: Critical events are the only ones that touch eligibility.
CREATE TRIGGER TRG_SafetyEvent_AfterInsert
AFTER INSERT ON SafetyEvent
FOR EACH ROW
BEGIN
    DECLARE v_SeverityLevel VARCHAR(100);

    SELECT SeverityLevel INTO v_SeverityLevel
    FROM EventSeverity WHERE SeverityID = NEW.SeverityID;

    IF v_SeverityLevel = 'Critical' THEN
        CALL sp_RecomputeDriverEligibility(NEW.DriverID); -- See sp_RecomputeDriverEligibility at line 39 in 3.driver_eligibility_and_safety_event_triggers.sql for the full recompute logic.
    END IF;
END;
//

DELIMITER ;


-- ==========================================
-- SUPPORTING PROCEDURE + TRIGGER: Penalty Evaluation
-- ==========================================
-- Nothing previously read PenaltyRule at all -- monthly scores never moved
-- unless something manually inserted DriverScorePenalty rows. This closes
-- that gap: every SafetyEvent insert evaluates against every matching rule
-- and applies whatever's due.
--
-- MATCHING: independent of RuleType. A rule matches an event if every
-- criterion it actually sets (SeverityID and/or EventTypeID) matches, and
-- NULL on a rule's column means "don't care" about that dimension.
-- CHK_PR_Target_Consistency only requires at least one of the two to be
-- non-null -- it does NOT force Base<->Severity / Conditional<->EventType
-- pairing, so a Base rule keyed on EventTypeID or a Conditional rule keyed
-- on SeverityID (see schema.sql's own commented-out edge-case examples)
-- both need to match correctly. RuleType only controls BEHAVIOR below
-- (apply immediately vs. count-and-threshold), not which column is checked.
--
-- HARD DEPENDENCY: requires a DriverMonthlySafetyScore row to already exist
-- for this driver's month (via sp_InitializeMonthlyScores) -- there's no
-- score row to attach the penalty to otherwise, and this procedure rejects
-- the insert rather than silently skipping the penalty. This means seeding
-- historical SafetyEvent data now requires initializing that historical
-- month's score row FIRST.
--
-- ONLY CORRECTLY HANDLES TimeWindowMonths = 1 for Conditional rules --
-- explicitly SIGNALs rather than silently mis-evaluating if this is ever
-- violated. A Conditional rule's window is treated as "the calendar month
-- this event falls in," not a rolling N-month window -- forced by
-- DriverScorePenalty attaching to exactly one DriverMonthlySafetyScoreID.
-- A true rolling window would double-count events that fall inside two
-- overlapping monthly evaluations near a month boundary, which isn't
-- solvable without changing what DriverScorePenalty attaches to -- so this
-- fails loudly instead of shipping an approximately-correct number.
 
DELIMITER //
 
CREATE PROCEDURE sp_EvaluatePenaltiesForEvent(IN p_EventID VARCHAR(100))
BEGIN
    DECLARE v_DriverID VARCHAR(20);
    DECLARE v_EventTypeID SMALLINT UNSIGNED;
    DECLARE v_SeverityID SMALLINT UNSIGNED;
    DECLARE v_EventTimestamp TIMESTAMP;
    DECLARE v_ScoreID INT UNSIGNED;
 
    DECLARE v_Done INT DEFAULT FALSE;
    DECLARE v_RuleID SMALLINT UNSIGNED;
    DECLARE v_RuleType VARCHAR(20);
    DECLARE v_RuleEventTypeID SMALLINT UNSIGNED;
    DECLARE v_RuleSeverityID SMALLINT UNSIGNED;
    DECLARE v_MinEventCount TINYINT UNSIGNED;
    DECLARE v_TimeWindowMonths TINYINT UNSIGNED;
    DECLARE v_PenaltyPoints DECIMAL(5,2);
    DECLARE v_MatchCount INT;
    DECLARE v_AlreadyApplied INT;
 
    -- See MATCHING note above -- deliberately not keyed off RuleType.
    DECLARE cur CURSOR FOR -- Declaration order is important here -- the cursor must be declared before the CONTINUE HANDLER.
        SELECT PenaltyRuleID, RuleType, EventTypeID, SeverityID, MinEventCount, TimeWindowMonths, PenaltyPoints
        FROM PenaltyRule
        WHERE (SeverityID IS NULL OR SeverityID = v_SeverityID)
          AND (EventTypeID IS NULL OR EventTypeID = v_EventTypeID);
        -- NOTE: The simplified WHERE SeverityID = v_SeverityID OR EventTypeID = v_EventTypeID is NOT correct 
        -- it would match a rule that only sets one of the two, but not the other, and would skip rules that set the other dimension.
        -- The above WHERE clause matches on whichever dimensions the rule actually sets, and ignores the ones it doesn't care about (NULL = "don't care").
        -- This prevents a PenaltyRule that sets both SeverityID and EventTypeID from being applied to an event that only matches one of the two, which is the correct behavior.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_Done = TRUE; -- Cursor loop termination handler
 
    SELECT DriverID, EventTypeID, SeverityID, EventTimestamp
    INTO v_DriverID, v_EventTypeID, v_SeverityID, v_EventTimestamp
    FROM SafetyEvent WHERE EventID = p_EventID;
 
    SELECT DriverMonthlySafetyScoreID INTO v_ScoreID
    FROM DriverMonthlySafetyScore
    WHERE DriverID = v_DriverID
      AND Month = MONTH(v_EventTimestamp)
      AND Year = YEAR(v_EventTimestamp);
 
    IF v_ScoreID IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot apply penalty: no DriverMonthlySafetyScore row exists for this driver/month. Run sp_InitializeMonthlyScores first.';
    END IF;

    -- Loop through all matching PenaltyRule rows and apply penalties as appropriate
    OPEN cur;
    penalty_loop: LOOP
        FETCH cur INTO v_RuleID, v_RuleType, v_RuleEventTypeID, v_RuleSeverityID, v_MinEventCount, v_TimeWindowMonths, v_PenaltyPoints;
        IF v_Done THEN
            LEAVE penalty_loop;
        END IF;
 
        IF v_RuleType = 'Base' THEN
            -- One penalty per event -- every matching event incurs its own
            -- deduction, guarded per-EventID so re-evaluation (if this
            -- procedure is ever called again for the same event) can't
            -- double-charge it.
            SELECT COUNT(*) INTO v_AlreadyApplied
            FROM DriverScorePenalty
            WHERE EventID = p_EventID AND PenaltyRuleID = v_RuleID;
 
            IF v_AlreadyApplied = 0 THEN
                INSERT INTO DriverScorePenalty
                    (DriverMonthlySafetyScoreID, PenaltyRuleID, EventID, PointsDeducted, DateApplied)
                VALUES
                    (v_ScoreID, v_RuleID, p_EventID, v_PenaltyPoints, v_EventTimestamp);
            END IF;
 
        ELSE -- Conditional
            IF v_TimeWindowMonths <> 1 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Conditional PenaltyRule has TimeWindowMonths <> 1: not supported by sp_EvaluatePenaltiesForEvent. See procedure header comment for why.';
            END IF;
 
            -- "More than N events matching this rule's criteria this month" --
            -- strictly greater than, matching the brief's wording exactly
            -- (N=3 means the 4th event is what crosses it, not the 3rd).
            -- Matches on whichever of EventTypeID/SeverityID this specific
            -- rule actually set, same NULL = "don't care" logic as the cursor.
            SELECT COUNT(*) INTO v_MatchCount
            FROM SafetyEvent
            WHERE DriverID = v_DriverID
              AND (v_RuleEventTypeID IS NULL OR EventTypeID = v_RuleEventTypeID)
              AND (v_RuleSeverityID IS NULL OR SeverityID = v_RuleSeverityID)
              AND MONTH(EventTimestamp) = MONTH(v_EventTimestamp)
              AND YEAR(EventTimestamp) = YEAR(v_EventTimestamp);
 
            IF v_MatchCount > v_MinEventCount THEN
                -- Fires once per month per rule -- once applied to this
                -- month's score row, subsequent events don't re-trigger it.
                SELECT COUNT(*) INTO v_AlreadyApplied
                FROM DriverScorePenalty
                WHERE DriverMonthlySafetyScoreID = v_ScoreID
                  AND PenaltyRuleID = v_RuleID;
 
                IF v_AlreadyApplied = 0 THEN
                    INSERT INTO DriverScorePenalty
                        (DriverMonthlySafetyScoreID, PenaltyRuleID, EventID, PointsDeducted, DateApplied)
                    VALUES
                        (v_ScoreID, v_RuleID, p_EventID, v_PenaltyPoints, v_EventTimestamp);
                END IF;
            END IF;
        END IF;
    END LOOP;
    CLOSE cur;
END;
//

-- AFTER INSERT: kept separate from TRG_SafetyEvent_AfterInsert (eligibility)
-- deliberately -- two different concerns, two triggers. MySQL fires multiple
-- AFTER INSERT triggers on the same table in creation order by default.
CREATE TRIGGER TRG_SafetyEvent_AfterInsert_EvaluatePenalties
AFTER INSERT ON SafetyEvent
FOR EACH ROW
BEGIN
    CALL sp_EvaluatePenaltiesForEvent(NEW.EventID); -- See sp_EvaluatePenaltiesForEvent at line 184 in 3.driver_eligibility_and_safety_event_triggers.sql for the full evaluation logic.
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGER: SafetyEvent - Historical Fact Lock
-- ==========================================

DELIMITER //

-- BEFORE UPDATE: An incident record is a historical fact once logged -- who,
-- what vehicle, what depot, what type/severity, when, and at what odometer
-- reading are all locked. ReviewState is the one column allowed to change,
-- but ONLY via the EventReview back-write triggers -- same session-flag
-- pattern as the Driver.DrivingEligibility guard, so a direct
-- UPDATE SafetyEvent SET ReviewState = ... can no longer silently bypass
-- the review workflow and skip the eligibility recompute that's supposed
-- to come with it.
CREATE TRIGGER TRG_SafetyEvent_BeforeUpdate
BEFORE UPDATE ON SafetyEvent
FOR EACH ROW
BEGIN
    IF NEW.DriverID <> OLD.DriverID
       OR NEW.VIN <> OLD.VIN
       OR NEW.DepotID <> OLD.DepotID
       OR NEW.EventTypeID <> OLD.EventTypeID
       OR NEW.SeverityID <> OLD.SeverityID
       OR NEW.EventTimestamp <> OLD.EventTimestamp
       OR NEW.Odometer <> OLD.Odometer THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify the recorded facts of a safety event. Only ReviewState may change, and only via the review workflow.';
    END IF;

    IF NEW.ReviewState <> OLD.ReviewState
       AND (@sfms_allow_reviewstate_write IS NULL OR @sfms_allow_reviewstate_write <> 1) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'ReviewState cannot be written directly; it is derived from EventReview.';
    END IF;
END;
//

DELIMITER ;

-- ==========================================================
-- EVENT REVIEW, COACHING & SCORING TRIGGERS  (4 of 5)
-- ==========================================================
-- Scope: the "downstream consequences" side of the safety system --
-- fn_EventReviewState and the EventReview close-guard/back-write
-- triggers, the DriverScorePenalty score cascade (including
-- automatic CoachingRecord creation), CoachingRecord completion
-- clearing eligibility, and the sp_InitializeMonthlyScores procedure.
--
-- Depends on: schema.sql, driver_eligibility_and_safety_event_triggers.sql
-- (calls sp_RecomputeDriverEligibility, defined there).
-- ==========================================================

-- ==========================================
-- SUPPORTING FUNCTION: EventReview Aggregation
-- ==========================================
-- Recomputes what SafetyEvent.ReviewState should be from the full set of
-- EventReview rows tied to an event -- same "recompute the whole picture,
-- don't patch incrementally" approach as the eligibility procedure above.
-- Returns NULL when no review has been assigned yet, signalling the caller
-- to leave SafetyEvent.ReviewState (Pending / No Review Required) untouched.

DELIMITER //

CREATE FUNCTION fn_EventReviewState(p_EventID VARCHAR(100))
RETURNS VARCHAR(50)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_Total INT DEFAULT 0;
    DECLARE v_Open INT DEFAULT 0;
    DECLARE v_Started INT DEFAULT 0;

    SELECT COUNT(*) INTO v_Total FROM EventReview WHERE EventID = p_EventID;

    IF v_Total = 0 THEN
        RETURN NULL;
    END IF;

    -- All reviewers Closed -> the event's review is fully Completed.
    SELECT COUNT(*) INTO v_Open
    FROM EventReview WHERE EventID = p_EventID AND Status <> 'Closed';

    IF v_Open = 0 THEN
        RETURN 'Completed';
    END IF;

    -- At least one reviewer has started looking -> In Review.
    SELECT COUNT(*) INTO v_Started
    FROM EventReview WHERE EventID = p_EventID AND Status IN ('Read', 'Commented');

    IF v_Started > 0 THEN
        RETURN 'In Review';
    END IF;

    -- Reviewer(s) exist but nobody's opened it yet.
    RETURN 'Assigned';
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGERS: EventReview - Close Guard & Back-write
-- ==========================================

DELIMITER //

-- BEFORE UPDATE: Can't close a review that was never read, and once Closed,
-- a review is a historical fact -- matches the "Can't be edited after being
-- closed" line in the CHK_ER_StatusConsistency comment in schema.sql, which
-- wasn't actually enforced anywhere until now.
CREATE TRIGGER TRG_EventReview_BeforeUpdate
BEFORE UPDATE ON EventReview
FOR EACH ROW
BEGIN
    IF OLD.Status = 'Closed' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify a review that has already been closed.';
    END IF;

    IF NEW.Status = 'Closed' AND OLD.Status = 'Unread' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot close a review that has not been read.';
    END IF;
END;
//

-- BEFORE INSERT: A review can't be born already Closed -- same "must be
-- Read first" rule as the BeforeUpdate guard, just covering the entry point
-- that guard can't see (INSERT has no OLD.Status to compare against).
CREATE TRIGGER TRG_EventReview_BeforeInsert
BEFORE INSERT ON EventReview
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Closed' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot insert a review as Closed; it must be read first.';
    END IF;
END;
//

-- AFTER INSERT: A new reviewer being assigned always moves the needle.
CREATE TRIGGER TRG_EventReview_AfterInsert
AFTER INSERT ON EventReview
FOR EACH ROW
BEGIN
    DECLARE v_NewState VARCHAR(50);
    DECLARE v_DriverID VARCHAR(20);

    SET v_NewState = fn_EventReviewState(NEW.EventID); -- See fn_EventReviewState at line 25 in 4.review_coaching_and_scoring_triggers.sql for the full aggregation logic.

    IF v_NewState IS NOT NULL THEN
        SET @sfms_allow_reviewstate_write = 1; -- Direct write override flag, so the trigger can update SafetyEvent.ReviewState without tripping its own guard.
        UPDATE SafetyEvent SET ReviewState = v_NewState WHERE EventID = NEW.EventID;
        SET @sfms_allow_reviewstate_write = NULL; -- Clear the override flag so future direct writes are blocked again.
    END IF;

    -- With the BeforeInsert guard above, a freshly inserted row can never
    -- itself be Closed, so this branch should be structurally unreachable
    -- today. Kept anyway, mirroring AfterUpdate exactly, as cheap insurance
    -- in case that guard is ever loosened later.
    IF v_NewState = 'Completed' THEN
        SELECT DriverID INTO v_DriverID FROM SafetyEvent WHERE EventID = NEW.EventID;
        CALL sp_RecomputeDriverEligibility(v_DriverID); -- See sp_RecomputeDriverEligibility at line 39 in 3.driver_eligibility_and_safety_event_triggers.sql for the full eligibility logic.
    END IF;
END;
//

-- AFTER UPDATE: Any status change re-syncs SafetyEvent.ReviewState, and if the
-- event just became fully Completed (all reviewers Closed), the driver's
-- eligibility may need to clear -- safe to always call the procedure here,
-- since it re-checks every condition rather than assuming this was the only one.
CREATE TRIGGER TRG_EventReview_AfterUpdate
AFTER UPDATE ON EventReview
FOR EACH ROW
BEGIN
    DECLARE v_NewState VARCHAR(50);
    DECLARE v_DriverID VARCHAR(20);

    IF OLD.Status <> NEW.Status THEN
        SET v_NewState = fn_EventReviewState(NEW.EventID);

        IF v_NewState IS NOT NULL THEN
            SET @sfms_allow_reviewstate_write = 1;
            UPDATE SafetyEvent SET ReviewState = v_NewState WHERE EventID = NEW.EventID;
            SET @sfms_allow_reviewstate_write = NULL;
        END IF;

        IF v_NewState = 'Completed' THEN
            SELECT DriverID INTO v_DriverID FROM SafetyEvent WHERE EventID = NEW.EventID;
            CALL sp_RecomputeDriverEligibility(v_DriverID); -- See sp_RecomputeDriverEligibility at line 39 in 3.driver_eligibility_and_safety_event_triggers.sql for the full eligibility logic.
        END IF;
    END IF;
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGERS: DriverScorePenalty - Score Cascade
-- ==========================================
-- NOTE: assumes DriverMonthlySafetyScore.Score is stored-and-decremented not computed-on-read. 
-- This trigger IS the decrement -- nothing else updates that column.

DELIMITER //

CREATE TRIGGER TRG_DriverScorePenalty_AfterInsert
AFTER INSERT ON DriverScorePenalty
FOR EACH ROW
BEGIN
    DECLARE v_DriverID VARCHAR(20);
    DECLARE v_NewScore DECIMAL(5,2);
    DECLARE v_OpenCoaching INT DEFAULT 0;
    DECLARE v_OpenRetraining INT DEFAULT 0;

    -- Step 1: apply the deduction.
    UPDATE DriverMonthlySafetyScore
    SET Score = Score - NEW.PointsDeducted
    WHERE DriverMonthlySafetyScoreID = NEW.DriverMonthlySafetyScoreID;

    -- Step 2: fetch the driver + freshly updated score.
    SELECT DriverID, Score INTO v_DriverID, v_NewScore
    FROM DriverMonthlySafetyScore
    WHERE DriverMonthlySafetyScoreID = NEW.DriverMonthlySafetyScoreID;

    -- Step 3: score <= 75 -> ensure a Safety Coaching requirement exists.
    -- Non-blocking -- doesn't touch DrivingEligibility. Guarded so repeated
    -- penalties in the same low-score window don't spawn duplicate records.
    IF v_NewScore <= 75 THEN
        SELECT COUNT(*) INTO v_OpenCoaching
        FROM CoachingRecord
        WHERE DriverID = v_DriverID
          AND CoachingType = 'Safety Coaching'
          AND Outcome IN ('Pending', 'In Progress');

        IF v_OpenCoaching = 0 THEN
            INSERT INTO CoachingRecord (DriverID, CoachingType, CoachingDate, Outcome)
            VALUES (v_DriverID, 'Safety Coaching', CURDATE(), 'Pending');
        END IF;
    END IF;

    -- Step 4: score <= 50 -> ensure a Retraining requirement exists. This one
    -- IS blocking, via sp_RecomputeDriverEligibility below.
    IF v_NewScore <= 50 THEN
        SELECT COUNT(*) INTO v_OpenRetraining
        FROM CoachingRecord
        WHERE DriverID = v_DriverID
          AND CoachingType = 'Retraining'
          AND Outcome <> 'Passed';

        IF v_OpenRetraining = 0 THEN
            INSERT INTO CoachingRecord (DriverID, CoachingType, CoachingDate, Outcome)
            VALUES (v_DriverID, 'Retraining', CURDATE(), 'Pending');
        END IF;
    END IF;

    -- Step 5: recompute regardless -- covers the case where this penalty
    -- pushed the score below 50 for the first time.
    CALL sp_RecomputeDriverEligibility(v_DriverID); -- See sp_RecomputeDriverEligibility at line 39 in 3.driver_eligibility_and_safety_event_triggers.sql for the full eligibility logic.
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGER: CoachingRecord - Completion Clears Eligibility
-- ==========================================

DELIMITER //

-- BEFORE UPDATE: DriverID, CoachingType, and CoachingDate are the "who/what/
-- when this was opened" facts -- locked once set, same pattern as
-- VehicleAssignment and MechanicWorkSession. Outcome and CompletionDate stay
-- open, since progressing a coaching record to Passed/Failed is the point.
CREATE TRIGGER TRG_CoachingRecord_BeforeUpdate
BEFORE UPDATE ON CoachingRecord
FOR EACH ROW
BEGIN
    IF NEW.DriverID <> OLD.DriverID
       OR NEW.CoachingType <> OLD.CoachingType
       OR NEW.CoachingDate <> OLD.CoachingDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify DriverID, CoachingType, or CoachingDate on an existing coaching record.';
    END IF;
END;
//

CREATE TRIGGER TRG_CoachingRecord_AfterUpdate
AFTER UPDATE ON CoachingRecord
FOR EACH ROW
BEGIN
    -- Only Retraining outcomes matter for eligibility; Safety Coaching and
    -- Licence Review never blocked in the first place, so nothing to clear.
    IF NEW.CoachingType = 'Retraining' AND OLD.Outcome <> NEW.Outcome THEN
        CALL sp_RecomputeDriverEligibility(NEW.DriverID); -- See sp_RecomputeDriverEligibility at line 39 in 3.driver_eligibility_and_safety_event_triggers.sql for the full eligibility logic.
    END IF;
END;
//

-- AFTER INSERT: covers a Retraining record created directly (staff manually
-- enrolling a driver) rather than via the DriverScorePenalty cascade above,
-- which already calls the procedure itself as part of its own insert.
CREATE TRIGGER TRG_CoachingRecord_AfterInsert
AFTER INSERT ON CoachingRecord
FOR EACH ROW
BEGIN
    IF NEW.CoachingType = 'Retraining' AND NEW.Outcome <> 'Passed' THEN
        CALL sp_RecomputeDriverEligibility(NEW.DriverID); -- See sp_RecomputeDriverEligibility at line 39 in 3.driver_eligibility_and_safety_event_triggers.sql for the full eligibility logic.
    END IF;
END;
//

DELIMITER ;


-- ==========================================
-- SUPPORTING PROCEDURE: Monthly Score Initialization
-- ==========================================
-- IMPORTANT: APPLICATION LAYER SIDE: Creates a DriverMonthlySafetyScore row at Score = 100 for every eligible
-- driver for a given month/year. Not a trigger -- there's no DML event that
-- means "a new month started," so this needs an explicit call, either from
-- a MySQL scheduled EVENT (not built here) or an app-side monthly job.
--
-- Idempotent by design (NOT EXISTS guard + the table's own
-- UC_DriverMonthlySafetyScore unique constraint as a backstop), so it's safe
-- to call more than once for the same month -- which matters, because
-- 'On Leave' drivers are deliberately included below. A driver who returns
-- from leave mid-month, or who's assigned a depot mid-month, needs this
-- re-run to pick them up; otherwise the first DriverScorePenalty against
-- them that month has no row to decrement.
--
-- Only 'Terminated' is excluded. Drivers with no CurrentDepotID are skipped
-- entirely (DepotID is NOT NULL on this table) -- worth revisiting if that
-- turns out to be a real scenario rather than an edge case.

DELIMITER //

CREATE PROCEDURE sp_InitializeMonthlyScores(IN p_Month TINYINT UNSIGNED, IN p_Year YEAR)
BEGIN
    INSERT INTO DriverMonthlySafetyScore (DriverID, Month, Year, DepotID, Score)
    SELECT d.DriverID, p_Month, p_Year, d.CurrentDepotID, 100.00
    FROM Driver d
    WHERE d.EmploymentStatus <> 'Terminated'
      AND d.CurrentDepotID IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM DriverMonthlySafetyScore dmss
          WHERE dmss.DriverID = d.DriverID
            AND dmss.Month = p_Month
            AND dmss.Year = p_Year
      );
END;
//

DELIMITER ;

-- Example call, for this month:
--   CALL sp_InitializeMonthlyScores(MONTH(CURDATE()), YEAR(CURDATE()));

-- ==========================================================
-- WORKSHOP OPERATIONS TRIGGERS  (5 of 5)
-- ==========================================================
-- Scope: MechanicWorkSession certification/employment gating, Part
-- inventory tracking on ActivityPart (stock deduction/restoration),
-- and the WarrantyClaim historical-fact lock.
--
-- Depends on: schema.sql
-- ==========================================================

-- ==========================================
-- TRIGGERS: MechanicWorkSession - Certification Gate
-- ==========================================

DELIMITER //

-- BEFORE INSERT: A mechanic can only log a session against an activity if
-- they're an active employee AND hold an active, unexpired certification
-- matching that activity's required cert type.
CREATE TRIGGER TRG_MechanicWorkSession_BeforeInsert
BEFORE INSERT ON MechanicWorkSession
FOR EACH ROW
BEGIN
    DECLARE v_EmploymentStatus VARCHAR(50);
    DECLARE v_RequiredCertTypeID SMALLINT UNSIGNED;
    DECLARE v_HasValidCert INT DEFAULT 0;

    -- Rule 1: same EmploymentStatus pattern as the VehicleAssignment gate --
    -- a suspended/terminated mechanic can't log billable work.
    SELECT EmploymentStatus INTO v_EmploymentStatus
    FROM Mechanic WHERE MechanicID = NEW.MechanicID;

    IF v_EmploymentStatus IS NULL OR v_EmploymentStatus <> 'Active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot log work session: mechanic is not currently an active employee.';
    END IF;

    -- Rule 2: mechanic must hold the specific certification this activity
    -- type requires, active and not expired.
    SELECT at.RequiredMechanicCertification INTO v_RequiredCertTypeID
    FROM MaintenanceActivity ma
    JOIN ActivityType at ON at.ActivityTypeID = ma.ActivityTypeID
    WHERE ma.ActivityID = NEW.ActivityID;

    SELECT COUNT(*) INTO v_HasValidCert
    FROM MechanicCertification mc
    WHERE mc.MechanicID = NEW.MechanicID
      AND mc.MechanicCertificationTypeID = v_RequiredCertTypeID
      AND mc.Status IN ('Active', 'Reinstated')
      AND mc.ExpiryDate > CURDATE();

    IF v_HasValidCert = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot log work session: mechanic lacks the required active certification for this activity type.';
    END IF;

END;
//

-- BEFORE UPDATE: MechanicID, ActivityID, and StartTime are locked once the
-- row exists -- who did the work, on what, and when they started is a
-- historical fact. Only EndTime is legitimately mutable (closing a session
-- out, or logging a break/re-start as a fresh row per the schema comment).
CREATE TRIGGER TRG_MechanicWorkSession_BeforeUpdate
BEFORE UPDATE ON MechanicWorkSession
FOR EACH ROW
BEGIN
    IF NEW.MechanicID <> OLD.MechanicID
       OR NEW.ActivityID <> OLD.ActivityID
       OR NEW.StartTime <> OLD.StartTime THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify MechanicID, ActivityID, or StartTime on an existing work session. Close it and log a new session instead.';
    END IF;
END;
//

DELIMITER ;
-- ==========================================
-- TRIGGERS: Part Inventory Tracking
-- ==========================================
-- Nothing previously decremented Part.CurrentStock when a part actually got
-- used on a job, despite the brief calling out reorder-threshold monitoring
-- as a real workshop-manager need (p.13) and the schema already having both
-- CurrentStock and ReorderThreshold to support it.

DELIMITER //

-- BEFORE INSERT: Can't use more of a part than is actually on the shelf.
-- CurrentStock is SMALLINT UNSIGNED, so an unguarded decrement below zero
-- wouldn't just be wrong, it would be a hard error (or silently clamp,
-- depending on SQL mode) -- better to reject the usage record outright with
-- a clear message than let the AFTER INSERT decrement below hit that wall.
--
-- Also validates ClaimID, if provided: WarrantyClaim belongs to exactly one
-- ActivityID (FK_WC_Activity), so a claim opened for a different job can't
-- be attached here.
CREATE TRIGGER TRG_ActivityPart_BeforeInsert
BEFORE INSERT ON ActivityPart
FOR EACH ROW
BEGIN
    DECLARE v_CurrentStock SMALLINT UNSIGNED;
    DECLARE v_ClaimActivityID INT UNSIGNED;

    SELECT CurrentStock INTO v_CurrentStock
    FROM Part WHERE PartNumber = NEW.PartNumber;

    IF v_CurrentStock IS NULL OR v_CurrentStock < NEW.QuantityUsed THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot use more of this part than is currently in stock.';
    END IF;

    IF NEW.ClaimID IS NOT NULL THEN
        SELECT ActivityID INTO v_ClaimActivityID
        FROM WarrantyClaim WHERE ClaimID = NEW.ClaimID;

        IF v_ClaimActivityID IS NULL OR v_ClaimActivityID <> NEW.ActivityID THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ClaimID does not belong to this ActivityID.';
        END IF;
    END IF;
END;
//

-- AFTER INSERT: Apply the deduction, now guaranteed safe by the gate above.
CREATE TRIGGER TRG_ActivityPart_AfterInsert
AFTER INSERT ON ActivityPart
FOR EACH ROW
BEGIN
    UPDATE Part
    SET CurrentStock = CurrentStock - NEW.QuantityUsed
    WHERE PartNumber = NEW.PartNumber;
END;
//

-- BEFORE UPDATE: ActivityID, PartNumber, and QuantityUsed are locked once
-- the row exists -- the AFTER INSERT decrement above already happened
-- against the original QuantityUsed, so silently changing it later would
-- desync CurrentStock from what was actually recorded as used. UnitCost is
-- locked for the same "historical fact" reasoning as everywhere else in
-- this project. ClaimID stays open, since attaching a warranty claim after
-- the fact is a normal, expected edit.
CREATE TRIGGER TRG_ActivityPart_BeforeUpdate
BEFORE UPDATE ON ActivityPart
FOR EACH ROW
BEGIN
    DECLARE v_ClaimActivityID INT UNSIGNED;

    IF NEW.ActivityID <> OLD.ActivityID
       OR NEW.PartNumber <> OLD.PartNumber
       OR NEW.QuantityUsed <> OLD.QuantityUsed
       OR NEW.UnitCost <> OLD.UnitCost THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify ActivityID, PartNumber, QuantityUsed, or UnitCost on an existing part-usage record. Only ClaimID may be updated.';
    END IF;

    IF NEW.ClaimID IS NOT NULL AND NOT (NEW.ClaimID <=> OLD.ClaimID) THEN
        SELECT ActivityID INTO v_ClaimActivityID
        FROM WarrantyClaim WHERE ClaimID = NEW.ClaimID;

        IF v_ClaimActivityID IS NULL OR v_ClaimActivityID <> NEW.ActivityID THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ClaimID does not belong to this ActivityID.';
        END IF;
    END IF;
END;
//

-- AFTER DELETE: Since QuantityUsed is locked (correction = delete + re-insert,
-- not edit), a delete without this would silently under-count real stock
-- forever -- undermining the reorder-threshold tracking this file exists for.
CREATE TRIGGER TRG_ActivityPart_AfterDelete
AFTER DELETE ON ActivityPart
FOR EACH ROW
BEGIN
    UPDATE Part
    SET CurrentStock = CurrentStock + OLD.QuantityUsed
    WHERE PartNumber = OLD.PartNumber;
END;
//

DELIMITER ;


-- ==========================================
-- TRIGGER: WarrantyClaim - Historical Fact Lock
-- ==========================================
-- The other gap in the project-wide "lock once written" pattern. ActivityID,
-- ClaimSource, and ClaimDate are the "what/why/when this was filed" facts --
-- locked once set. Status and ResolutionDate stay open, since progressing a
-- claim through Pending -> Approved/Rejected/Settled is the point.

DELIMITER //

CREATE TRIGGER TRG_WarrantyClaim_BeforeUpdate
BEFORE UPDATE ON WarrantyClaim
FOR EACH ROW
BEGIN
    IF NEW.ActivityID <> OLD.ActivityID
       OR NEW.ClaimSource <> OLD.ClaimSource
       OR NEW.ClaimDate <> OLD.ClaimDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot modify ActivityID, ClaimSource, or ClaimDate on an existing warranty claim.';
    END IF;
END;
//

DELIMITER ;

