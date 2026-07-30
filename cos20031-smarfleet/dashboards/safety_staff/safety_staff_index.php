<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Safety Staff']);
require_once __DIR__ . '/../../config/db.php';

$unresolvedCount = $pdo->query(
    "SELECT COUNT(*) FROM safetyevent WHERE ReviewState NOT IN ('Completed', 'No Review Required')"
)->fetchColumn();

$highRiskCount = $pdo->query(
    "SELECT COUNT(*) FROM drivermonthlysafetyscore
     WHERE Month = MONTH(CURDATE()) AND Year = YEAR(CURDATE()) AND Score <= 75"
)->fetchColumn();

$expiringCertCount = $pdo->query(
    "SELECT COUNT(*) FROM drivercertification
     WHERE Status IN ('Active', 'Reinstated') AND ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)"
)->fetchColumn();

$retrainingCount = $pdo->query(
    "SELECT COUNT(DISTINCT DriverID) FROM coachingrecord
     WHERE CoachingType = 'Retraining' AND Outcome <> 'Passed'"
)->fetchColumn();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Safety Staff Dashboard</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <h2>Safety Staff Dashboard</h2>

    <div class="card-grid">
        <div class="card">
            <h3>Unresolved Incidents</h3>
            <div class="stat-value score-critical"><?= htmlspecialchars($unresolvedCount) ?></div>
        </div>
        <div class="card">
            <h3>High-Risk Drivers (this month)</h3>
            <div class="stat-value score-warning"><?= htmlspecialchars($highRiskCount) ?></div>
        </div>
        <div class="card">
            <h3>Certifications Expiring (30 days)</h3>
            <div class="stat-value score-warning"><?= htmlspecialchars($expiringCertCount) ?></div>
        </div>
        <div class="card">
            <h3>Drivers Needing Retraining</h3>
            <div class="stat-value score-critical"><?= htmlspecialchars($retrainingCount) ?></div>
        </div>
    </div>

    <div class="card-grid">
        <a class="card" href="incidents.php">
            <h3>Incident Review</h3>
            <p>Search and filter incidents by driver, vehicle, depot, event type, severity, and date. Review and comment on events.</p>
        </a>
        <a class="card" href="driver_risk.php">
            <h3>Driver Risk</h3>
            <p>High-risk drivers by safety score, repeated event rankings, and retraining requirements.</p>
        </a>
        <a class="card" href="depot_trends.php">
            <h3>Depot Safety Trends</h3>
            <p>Compare incident counts across depots by month, event type, and severity.</p>
        </a>
        <a class="card" href="certifications.php">
            <h3>Licence &amp; Certification Tracking</h3>
            <p>Certifications expiring soon or already expired.</p>
        </a>
        <a class="card" href="coaching.php">
            <h3>Coaching Records</h3>
            <p>View and record coaching/retraining outcomes.</p>
        </a>
        <a class="card" href="severe_vehicles.php">
            <h3>Vehicles with Severe Incidents</h3>
            <p>Vehicles associated with High/Critical severity events.</p>
        </a>
        <a class="card" href="cert_audit.php">
            <h3>Certification Audit</h3>
            <p>Vehicle assignments that became invalid after a certification was voided.</p>
        </a>
    </div>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
