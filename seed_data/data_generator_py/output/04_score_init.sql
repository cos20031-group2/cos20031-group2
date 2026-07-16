-- ==========================================================
-- 04 - MONTHLY SCORE INITIALIZATION
-- ==========================================================
-- Calls sp_InitializeMonthlyScores for every calendar month touched by the n-month window, so DriverMonthlySafetyScore rows exist before any SafetyEvent is inserted in stage 08.
-- ==========================================================

CALL sp_InitializeMonthlyScores(7, 2025);

CALL sp_InitializeMonthlyScores(8, 2025);

CALL sp_InitializeMonthlyScores(9, 2025);

CALL sp_InitializeMonthlyScores(10, 2025);

CALL sp_InitializeMonthlyScores(11, 2025);

CALL sp_InitializeMonthlyScores(12, 2025);

CALL sp_InitializeMonthlyScores(1, 2026);

CALL sp_InitializeMonthlyScores(2, 2026);

CALL sp_InitializeMonthlyScores(3, 2026);

CALL sp_InitializeMonthlyScores(4, 2026);

CALL sp_InitializeMonthlyScores(5, 2026);

CALL sp_InitializeMonthlyScores(6, 2026);

CALL sp_InitializeMonthlyScores(7, 2026);

