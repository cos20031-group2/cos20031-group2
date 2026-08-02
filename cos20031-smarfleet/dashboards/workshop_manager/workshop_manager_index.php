<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';

$openJobs = $pdo->query("SELECT COUNT(*) FROM maintenancejob WHERE DateClosed IS NULL")->fetchColumn();
$unresolvedAlerts = $pdo->query("SELECT COUNT(*) FROM predictivealert WHERE AlertStatus <> 'Resolved'")->fetchColumn();
$urgentAlerts = $pdo->query("SELECT COUNT(*) FROM predictivealert WHERE AlertStatus = 'Urgent Repair Standby'")->fetchColumn();
$overdueServices = $pdo->query(
    "SELECT COUNT(*) FROM scheduledservice WHERE Status IN ('Scheduled', 'In Progress') AND ScheduledDate <= CURDATE()"
)->fetchColumn();
$belowThreshold = $pdo->query("SELECT COUNT(*) FROM part WHERE CurrentStock < ReorderThreshold")->fetchColumn();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Workshop Manager Dashboard</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <h2>Workshop Manager Dashboard</h2>

    <div class="card-grid">
        <div class="card">
            <h3>Open Jobs</h3>
            <div class="stat-value"><?= htmlspecialchars($openJobs) ?></div>
        </div>
        <div class="card">
            <h3>Unresolved Alerts</h3>
            <div class="stat-value score-warning"><?= htmlspecialchars($unresolvedAlerts) ?></div>
        </div>
        <div class="card">
            <h3>Urgent Repair Standby</h3>
            <div class="stat-value score-critical"><?= htmlspecialchars($urgentAlerts) ?></div>
        </div>
        <div class="card">
            <h3>Overdue Services</h3>
            <div class="stat-value score-critical"><?= htmlspecialchars($overdueServices) ?></div>
        </div>
        <div class="card">
            <h3>Parts Below Reorder Threshold</h3>
            <div class="stat-value score-warning"><?= htmlspecialchars($belowThreshold) ?></div>
        </div>
    </div>

    <div class="card-grid">
        <a class="card" href="alerts.php">
            <h3>Predictive Alerts</h3>
            <p>Monitor alerts and identify vehicles requiring urgent repair.</p>
        </a>
        <a class="card" href="workload.php">
            <h3>Workshop Workload</h3>
            <p>Open jobs and average turnaround per workshop.</p>
        </a>
        <a class="card" href="jobs.php">
            <h3>Maintenance Jobs</h3>
            <p>Create jobs, add activities, record parts usage, close jobs.</p>
        </a>
        <a class="card" href="vehicle_maintenance_report.php">
            <h3>Downtime &amp; Repeat Failures</h3>
            <p>Vehicle downtime totals and repeated component failures.</p>
        </a>
        <a class="card" href="cost_comparison.php">
            <h3>Maintenance Cost Comparison</h3>
            <p>Compare maintenance costs between vehicle manufacturers/models.</p>
        </a>
        <a class="card" href="scheduled_services.php">
            <h3>Scheduled Services</h3>
            <p>Overdue services, vehicles awaiting inspection, and service scheduling.</p>
        </a>
        <a class="card" href="parts.php">
            <h3>Parts Inventory</h3>
            <p>Stock levels, reorder thresholds, and restocking.</p>
        </a>
        <a class="card" href="mechanic_certifications.php">
            <h3>Mechanic Certifications</h3>
            <p>Issue, revoke, void, or reinstate mechanic certifications.</p>
        </a>
        <a class="card" href="suppliers.php">
            <h3>Suppliers</h3>
            <p>Compare pricing and lead time across suppliers per part.</p>
        </a>
    </div>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
