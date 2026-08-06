CREATE INDEX idx_se_driver_time        ON SafetyEvent(DriverID, EventTimestamp DESC);
CREATE INDEX idx_se_vin_time           ON SafetyEvent(VIN, EventTimestamp DESC);
CREATE INDEX idx_se_depot_time         ON SafetyEvent(DepotID, EventTimestamp DESC);
CREATE INDEX idx_se_review_state_time  ON SafetyEvent(ReviewState, EventTimestamp);
CREATE INDEX idx_se_event_type_driver  ON SafetyEvent(EventTypeID, DriverID);
CREATE INDEX idx_dmss_year_month_score ON DriverMonthlySafetyScore(Year, Month, Score);
CREATE INDEX idx_dc_status_expiry      ON DriverCertification(Status, ExpiryDate);
CREATE INDEX idx_mj_vin_date           ON MaintenanceJob(VIN, DateOpened DESC);
CREATE INDEX idx_mj_workshop_dates     ON MaintenanceJob(WorkshopID, DateClosed, DateOpened);
CREATE INDEX idx_ma_repeated_fault     ON MaintenanceActivity(RepeatedFaultFlag, ActivityTypeID);
CREATE INDEX idx_v_depot_status        ON Vehicle(DepotID, OperationalStatus);
CREATE INDEX idx_va_status_depot       ON VehicleAssignment(AssignmentStatus, DepotID);
CREATE INDEX idx_pa_status_date        ON PredictiveAlert(AlertStatus, DateGenerated);
CREATE INDEX idx_ss_status_date        ON ScheduledService(Status, ScheduledDate);
CREATE INDEX idx_mws_mechanic_activity ON MechanicWorkSession(MechanicID, ActivityID, StartTime);

-- Optional (commented out):
-- CREATE INDEX idx_v_manufacturer_model ON Vehicle(Manufacturer, Model, VIN);
-- CREATE INDEX idx_va_driver_start      ON VehicleAssignment(DriverID, StartDate);
-- CREATE INDEX idx_cr_driver_date       ON CoachingRecord(DriverID, CoachingDate DESC);
-- CREATE INDEX idx_cr_type_outcome      ON CoachingRecord(CoachingType, Outcome);
-- CREATE INDEX idx_wc_source_date       ON WarrantyClaim(ClaimSource, ClaimDate DESC);