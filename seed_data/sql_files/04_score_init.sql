-- ==========================================================
-- 04 - MONTHLY SCORE INITIALIZATION
-- ==========================================================
-- Calls sp_InitializeMonthlyScores for every calendar month touched by the 6-month window, so DriverMonthlySafetyScore rows exist before any SafetyEvent is inserted in stage 08.
-- ==========================================================

CALL sp_InitializeMonthlyScores(1, 2026);

CALL sp_InitializeMonthlyScores(2, 2026);

CALL sp_InitializeMonthlyScores(3, 2026);

CALL sp_InitializeMonthlyScores(4, 2026);

CALL sp_InitializeMonthlyScores(5, 2026);

CALL sp_InitializeMonthlyScores(6, 2026);

CALL sp_InitializeMonthlyScores(7, 2026);

