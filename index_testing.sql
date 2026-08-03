-- ==========================================================
-- 1. SafetyEvent Indexes (The heaviest table)
-- ==========================================================

-- IDX 1: idx_se_driver_time (For Q9a) 
ANALYZE FORMAT=JSON SELECT se.EventID, se.EventTimestamp, v.Model FROM SafetyEvent se JOIN Vehicle v ON v.VIN = se.VIN WHERE se.DriverID = 'D-0002' ORDER BY se.EventTimestamp DESC;
CREATE INDEX idx_se_driver_time ON SafetyEvent(DriverID, EventTimestamp DESC);
ANALYZE FORMAT=JSON SELECT se.EventID, se.EventTimestamp, v.Model FROM SafetyEvent se JOIN Vehicle v ON v.VIN = se.VIN WHERE se.DriverID = 'D-0002' ORDER BY se.EventTimestamp DESC;
ALTER TABLE SafetyEvent DROP FOREIGN KEY FK_SE_Driver;
DROP INDEX idx_se_driver_time ON SafetyEvent;
ALTER TABLE SafetyEvent ADD CONSTRAINT FK_SE_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID);

-- IDX 2: idx_se_vin_time (For Q11 / Q27) 
ANALYZE FORMAT=JSON SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se WHERE se.VIN = 'DZRECBSNBKSJ7HP6T' ORDER BY se.EventTimestamp DESC;
CREATE INDEX idx_se_vin_time ON SafetyEvent(VIN, EventTimestamp DESC);
ANALYZE FORMAT=JSON SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se WHERE se.VIN = 'DZRECBSNBKSJ7HP6T' ORDER BY se.EventTimestamp DESC;
ALTER TABLE SafetyEvent DROP FOREIGN KEY FK_SE_Vehicle;
DROP INDEX idx_se_vin_time ON SafetyEvent;
ALTER TABLE SafetyEvent ADD CONSTRAINT FK_SE_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN);

-- IDX 3: idx_se_depot_time (For Q3 / Q8) 
ANALYZE FORMAT=JSON SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se WHERE se.DepotID = 1 ORDER BY se.EventTimestamp DESC;
CREATE INDEX idx_se_depot_time ON SafetyEvent(DepotID, EventTimestamp DESC);
ANALYZE FORMAT=JSON SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se WHERE se.DepotID = 1 ORDER BY se.EventTimestamp DESC;
ALTER TABLE SafetyEvent DROP FOREIGN KEY FK_SE_Depot;
DROP INDEX idx_se_depot_time ON SafetyEvent;
ALTER TABLE SafetyEvent ADD CONSTRAINT FK_SE_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID);

-- IDX 4: idx_se_review_state_time (For Q5a) 
ANALYZE FORMAT=JSON SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se WHERE se.ReviewState = 'Pending' ORDER BY se.EventTimestamp;
CREATE INDEX idx_se_review_state_time ON SafetyEvent(ReviewState, EventTimestamp);
ANALYZE FORMAT=JSON SELECT se.EventID, se.EventTimestamp FROM SafetyEvent se WHERE se.ReviewState = 'Pending' ORDER BY se.EventTimestamp;
DROP INDEX idx_se_review_state_time ON SafetyEvent;

-- IDX 5: idx_se_event_type_driver (For Q10) 
ANALYZE FORMAT=JSON SELECT se.DriverID, COUNT(*) FROM SafetyEvent se WHERE se.EventTypeID = 3 GROUP BY se.DriverID;
CREATE INDEX idx_se_event_type_driver ON SafetyEvent(EventTypeID, DriverID);
ANALYZE FORMAT=JSON SELECT se.DriverID, COUNT(*) FROM SafetyEvent se WHERE se.EventTypeID = 3 GROUP BY se.DriverID;
ALTER TABLE SafetyEvent DROP FOREIGN KEY FK_SE_EventType;
DROP INDEX idx_se_event_type_driver ON SafetyEvent;
ALTER TABLE SafetyEvent ADD CONSTRAINT FK_SE_EventType FOREIGN KEY (EventTypeID) REFERENCES EventType(EventTypeID);


-- ==========================================================
-- 2. DriverMonthlySafetyScore Indexes
-- ==========================================================

-- IDX 6: idx_dmss_driver_year_month (For Q9b) 
ANALYZE FORMAT=JSON SELECT Year, Month, Score FROM DriverMonthlySafetyScore WHERE DriverID = 'D-0002' ORDER BY Year, Month;
CREATE INDEX idx_dmss_driver_year_month ON DriverMonthlySafetyScore(DriverID, Year, Month);
ANALYZE FORMAT=JSON SELECT Year, Month, Score FROM DriverMonthlySafetyScore WHERE DriverID = 'D-0002' ORDER BY Year, Month;
ALTER TABLE DriverMonthlySafetyScore DROP FOREIGN KEY FK_DMSS_Driver;
DROP INDEX idx_dmss_driver_year_month ON DriverMonthlySafetyScore;
ALTER TABLE DriverMonthlySafetyScore ADD CONSTRAINT FK_DMSS_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID);

-- IDX 7: idx_dmss_year_month_score (For Q2a) 
ANALYZE FORMAT=JSON SELECT DriverID, Score FROM DriverMonthlySafetyScore WHERE Month = 12 AND Year = 2025 ORDER BY Score;
CREATE INDEX idx_dmss_year_month_score ON DriverMonthlySafetyScore(Year, Month, Score);
ANALYZE FORMAT=JSON SELECT DriverID, Score FROM DriverMonthlySafetyScore WHERE Month = 12 AND Year = 2025 ORDER BY Score;
DROP INDEX idx_dmss_year_month_score ON DriverMonthlySafetyScore;


-- ==========================================================
-- 3. Certification Indexes
-- ==========================================================

-- IDX 8: idx_dc_status_expiry (For Q4 / Q12) 
ANALYZE FORMAT=JSON SELECT DriverID, ExpiryDate FROM DriverCertification WHERE Status = 'Active' AND ExpiryDate <= '2026-06-30' ORDER BY ExpiryDate;
CREATE INDEX idx_dc_status_expiry ON DriverCertification(Status, ExpiryDate);
ANALYZE FORMAT=JSON SELECT DriverID, ExpiryDate FROM DriverCertification WHERE Status = 'Active' AND ExpiryDate <= '2026-06-30' ORDER BY ExpiryDate;
DROP INDEX idx_dc_status_expiry ON DriverCertification;

-- IDX 9: idx_mc_status_expiry_type (For Q17 / Q26) 
ANALYZE FORMAT=JSON SELECT MechanicID, ExpiryDate FROM MechanicCertification WHERE Status = 'Active' AND ExpiryDate > CURDATE() AND MechanicCertificationTypeID = 1;
CREATE INDEX idx_mc_status_expiry_type ON MechanicCertification(Status, ExpiryDate, MechanicCertificationTypeID);
ANALYZE FORMAT=JSON SELECT MechanicID, ExpiryDate FROM MechanicCertification WHERE Status = 'Active' AND ExpiryDate > CURDATE() AND MechanicCertificationTypeID = 1;
DROP INDEX idx_mc_status_expiry_type ON MechanicCertification;

-- IDX 10: idx_mc_mechanic_type_issue (For Q30) 
ANALYZE FORMAT=JSON SELECT MechanicCertificationTypeID, IssueDate FROM MechanicCertification WHERE MechanicID = 'ME-0001' ORDER BY IssueDate;
CREATE INDEX idx_mc_mechanic_type_issue ON MechanicCertification(MechanicID, MechanicCertificationTypeID, IssueDate);
ANALYZE FORMAT=JSON SELECT MechanicCertificationTypeID, IssueDate FROM MechanicCertification WHERE MechanicID = 'ME-0001' ORDER BY IssueDate;
ALTER TABLE MechanicCertification DROP FOREIGN KEY FK_MC_Mechanic;
DROP INDEX idx_mc_mechanic_type_issue ON MechanicCertification;
ALTER TABLE MechanicCertification ADD CONSTRAINT FK_MC_Mechanic FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID);


-- ==========================================================
-- 4. Maintenance & Workshop Indexes
-- ==========================================================

-- IDX 11: idx_mj_vin_date (For Q27 / Q20) 
ANALYZE FORMAT=JSON SELECT JobID, DateOpened FROM MaintenanceJob WHERE VIN = 'DZRECBSNBKSJ7HP6T' ORDER BY DateOpened DESC;
CREATE INDEX idx_mj_vin_date ON MaintenanceJob(VIN, DateOpened DESC);
ANALYZE FORMAT=JSON SELECT JobID, DateOpened FROM MaintenanceJob WHERE VIN = 'DZRECBSNBKSJ7HP6T' ORDER BY DateOpened DESC;
ALTER TABLE MaintenanceJob DROP FOREIGN KEY FK_MJ_Vehicle;
DROP INDEX idx_mj_vin_date ON MaintenanceJob;
ALTER TABLE MaintenanceJob ADD CONSTRAINT FK_MJ_Vehicle FOREIGN KEY (VIN) REFERENCES Vehicle(VIN);

-- IDX 12: idx_mj_workshop_dates (For Q16) 
ANALYZE FORMAT=JSON SELECT JobID, DateClosed FROM MaintenanceJob WHERE WorkshopID = 1;
CREATE INDEX idx_mj_workshop_dates ON MaintenanceJob(WorkshopID, DateClosed, DateOpened);
ANALYZE FORMAT=JSON SELECT JobID, DateClosed FROM MaintenanceJob WHERE WorkshopID = 1;
ALTER TABLE MaintenanceJob DROP FOREIGN KEY FK_MJ_Workshop;
DROP INDEX idx_mj_workshop_dates ON MaintenanceJob;
ALTER TABLE MaintenanceJob ADD CONSTRAINT FK_MJ_Workshop FOREIGN KEY (WorkshopID) REFERENCES Workshop(WorkshopID);

-- IDX 13: idx_ma_repeated_fault (For Q23) - WARNING: Boolean indexes are risky! - (Status: Improved Time, there aren't as many rows where RepeatedFaultFlag = TRUE)
ANALYZE FORMAT=JSON SELECT ActivityID, ActivityTypeID FROM MaintenanceActivity WHERE RepeatedFaultFlag = TRUE;
CREATE INDEX idx_ma_repeated_fault ON MaintenanceActivity(RepeatedFaultFlag, ActivityTypeID);
ANALYZE FORMAT=JSON SELECT ActivityID, ActivityTypeID FROM MaintenanceActivity WHERE RepeatedFaultFlag = TRUE;
DROP INDEX idx_ma_repeated_fault ON MaintenanceActivity;


-- ==========================================================
-- 5. Vehicle & Assignment Indexes
-- ==========================================================

-- IDX 14: idx_v_depot_status (For Q32) 
ANALYZE FORMAT=JSON SELECT VIN, OperationalStatus FROM Vehicle WHERE DepotID = 1 AND OperationalStatus = 2; 
CREATE INDEX idx_v_depot_status ON Vehicle(DepotID, OperationalStatus);
ANALYZE FORMAT=JSON SELECT VIN, OperationalStatus FROM Vehicle WHERE DepotID = 1 AND OperationalStatus = 2;
ALTER TABLE Vehicle DROP FOREIGN KEY FK_Vehicle_Depot;
DROP INDEX idx_v_depot_status ON Vehicle;
ALTER TABLE Vehicle ADD CONSTRAINT FK_Vehicle_Depot FOREIGN KEY (DepotID) REFERENCES Depot(DepotID);

-- IDX 15: idx_v_manufacturer_model (For Q21) 
ANALYZE FORMAT=JSON SELECT VIN, Model FROM Vehicle WHERE Manufacturer = 'Ford' AND Model = 'Ford H350';
CREATE INDEX idx_v_manufacturer_model ON Vehicle(Manufacturer, Model, VIN);
ANALYZE FORMAT=JSON SELECT VIN, Model FROM Vehicle WHERE Manufacturer = 'Ford' AND Model = 'Ford H350';
DROP INDEX idx_v_manufacturer_model ON Vehicle;

-- IDX 16: idx_va_status_depot (For Q33) 
ANALYZE FORMAT=JSON SELECT AssignmentID, DriverID FROM VehicleAssignment WHERE AssignmentStatus = 'In Operation' AND DepotID = 1;
CREATE INDEX idx_va_status_depot ON VehicleAssignment(AssignmentStatus, DepotID);
ANALYZE FORMAT=JSON SELECT AssignmentID, DriverID FROM VehicleAssignment WHERE AssignmentStatus = 'In Operation' AND DepotID = 1;
DROP INDEX idx_va_status_depot ON VehicleAssignment;

-- IDX 17: idx_va_driver_start (For Q13a) 
ANALYZE FORMAT=JSON SELECT AssignmentID, StartDate FROM VehicleAssignment WHERE DriverID = 'D-0012' ORDER BY StartDate;
CREATE INDEX idx_va_driver_start ON VehicleAssignment(DriverID, StartDate);
ANALYZE FORMAT=JSON SELECT AssignmentID, StartDate FROM VehicleAssignment WHERE DriverID = 'D-0012' ORDER BY StartDate;
ALTER TABLE VehicleAssignment DROP FOREIGN KEY FK_VA_Driver;
DROP INDEX idx_va_driver_start ON VehicleAssignment;
ALTER TABLE VehicleAssignment ADD CONSTRAINT FK_VA_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID);


-- ==========================================================
-- 6. Alerts, Schedules & Coaching Indexes
-- ==========================================================

-- IDX 18: idx_pa_status_date (For Q5b / Q15) 
ANALYZE FORMAT=JSON SELECT AlertID, DateGenerated FROM PredictiveAlert WHERE AlertStatus = 'Urgent Repair Standby' ORDER BY DateGenerated;
CREATE INDEX idx_pa_status_date ON PredictiveAlert(AlertStatus, DateGenerated);
ANALYZE FORMAT=JSON SELECT AlertID, DateGenerated FROM PredictiveAlert WHERE AlertStatus = 'Urgent Repair Standby' ORDER BY DateGenerated;
DROP INDEX idx_pa_status_date ON PredictiveAlert;

-- IDX 19: idx_ss_status_date (For Q22) 
ANALYZE FORMAT=JSON SELECT ScheduleID, ScheduledDate FROM ScheduledService WHERE Status = 'Scheduled' AND ScheduledDate <= CURDATE() ORDER BY ScheduledDate;
CREATE INDEX idx_ss_status_date ON ScheduledService(Status, ScheduledDate);
ANALYZE FORMAT=JSON SELECT ScheduleID, ScheduledDate FROM ScheduledService WHERE Status = 'Scheduled' AND ScheduledDate <= CURDATE() ORDER BY ScheduledDate;
DROP INDEX idx_ss_status_date ON ScheduledService;

-- IDX 20: idx_cr_driver_date (For Q6) 
ANALYZE FORMAT=JSON SELECT CoachingRecordID, CoachingDate FROM CoachingRecord WHERE DriverID = 'D-0002' ORDER BY CoachingDate DESC;
CREATE INDEX idx_cr_driver_date ON CoachingRecord(DriverID, CoachingDate DESC);
ANALYZE FORMAT=JSON SELECT CoachingRecordID, CoachingDate FROM CoachingRecord WHERE DriverID = 'D-0002' ORDER BY CoachingDate DESC;
ALTER TABLE CoachingRecord DROP FOREIGN KEY FK_CR_Driver;
DROP INDEX idx_cr_driver_date ON CoachingRecord;
ALTER TABLE CoachingRecord ADD CONSTRAINT FK_CR_Driver FOREIGN KEY (DriverID) REFERENCES Driver(DriverID);

-- IDX 21: idx_cr_type_outcome (For Q7) 
ANALYZE FORMAT=JSON SELECT DriverID, Outcome FROM CoachingRecord WHERE CoachingType = 'Retraining' AND Outcome = 'Failed';
CREATE INDEX idx_cr_type_outcome ON CoachingRecord(CoachingType, Outcome);
ANALYZE FORMAT=JSON SELECT DriverID, Outcome FROM CoachingRecord WHERE CoachingType = 'Retraining' AND Outcome = 'Failed';
DROP INDEX idx_cr_type_outcome ON CoachingRecord;


-- ==========================================================
-- 7. Extension / Workshop Ops Indexes
-- ==========================================================

-- IDX 22: idx_mws_mechanic_activity (For Q31) 
ANALYZE FORMAT=JSON SELECT SessionID, ActivityID FROM MechanicWorkSession WHERE MechanicID = 'ME-0001' ORDER BY ActivityID;
CREATE INDEX idx_mws_mechanic_activity ON MechanicWorkSession(MechanicID, ActivityID, StartTime);
ANALYZE FORMAT=JSON SELECT SessionID, ActivityID FROM MechanicWorkSession WHERE MechanicID = 'ME-0001' ORDER BY ActivityID;
ALTER TABLE MechanicWorkSession DROP FOREIGN KEY FK_MWS_Mechanic;
DROP INDEX idx_mws_mechanic_activity ON MechanicWorkSession;
ALTER TABLE MechanicWorkSession ADD CONSTRAINT FK_MWS_Mechanic FOREIGN KEY (MechanicID) REFERENCES Mechanic(MechanicID);

-- IDX 23: idx_ps_part_primary_cost (For Q29)
ANALYZE FORMAT=JSON SELECT SupplierID, UnitCost FROM PartSupplier WHERE PartNumber = 1 ORDER BY IsPrimary DESC, UnitCost;
CREATE INDEX idx_ps_part_primary_cost ON PartSupplier(PartNumber, IsPrimary DESC, UnitCost);
ANALYZE FORMAT=JSON SELECT SupplierID, UnitCost FROM PartSupplier WHERE PartNumber = 1 ORDER BY IsPrimary DESC, UnitCost;
DROP INDEX idx_ps_part_primary_cost ON PartSupplier;

-- IDX 24: idx_wc_source_date (For Q28) 
ANALYZE FORMAT=JSON SELECT ClaimID, ClaimDate FROM WarrantyClaim WHERE ClaimSource = 'Parts Supplier' ORDER BY ClaimDate DESC;
CREATE INDEX idx_wc_source_date ON WarrantyClaim(ClaimSource, ClaimDate DESC);
ANALYZE FORMAT=JSON SELECT ClaimID, ClaimDate FROM WarrantyClaim WHERE ClaimSource = 'Parts Supplier' ORDER BY ClaimDate DESC;
DROP INDEX idx_wc_source_date ON WarrantyClaim;