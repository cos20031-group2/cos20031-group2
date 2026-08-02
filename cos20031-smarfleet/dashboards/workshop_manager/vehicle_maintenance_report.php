<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$perPage = 10;

// Q20: downtime
$downtimePage = currentPage('downtime_page');
$totalDowntime = (int)$pdo->query('SELECT COUNT(DISTINCT mj.VIN) FROM maintenancejob mj')->fetchColumn();
$totalDowntimePages = max(1, (int)ceil($totalDowntime / $perPage));
$downtimePage = min($downtimePage, $totalDowntimePages);
$downtimeOffset = ($downtimePage - 1) * $perPage;

$downtime = $pdo->query(
    "SELECT
        v.VIN, v.Model, v.Manufacturer, d.DepotName,
        COUNT(mj.JobID) AS JobCount,
        SUM(CASE WHEN mj.DateClosed IS NOT NULL THEN mj.Downtime ELSE 0 END) AS RecordedDowntimeHours,
        SUM(CASE WHEN mj.DateClosed IS NULL
                 THEN TIMESTAMPDIFF(HOUR, mj.DateOpened, NOW()) ELSE 0 END) AS InProgressEstimateHours,
        SUM(CASE WHEN mj.DateClosed IS NOT NULL
                 THEN mj.Downtime ELSE TIMESTAMPDIFF(HOUR, mj.DateOpened, NOW()) END) AS TotalDowntimeHours
     FROM maintenancejob mj
     JOIN vehicle v ON v.VIN = mj.VIN
     JOIN depot d ON d.DepotID = v.DepotID
     GROUP BY v.VIN, v.Model, v.Manufacturer, d.DepotName
     ORDER BY TotalDowntimeHours DESC
     LIMIT $perPage OFFSET $downtimeOffset"
)->fetchAll();

// Q23: repeated component failures
$repeatPage = currentPage('repeat_page');
$totalRepeat = (int)$pdo->query(
    "SELECT COUNT(*) FROM (
        SELECT mj.VIN, at.ActivityType FROM maintenanceactivity ma
        JOIN maintenancejob mj ON mj.JobID = ma.JobID
        JOIN activitytype at ON at.ActivityTypeID = ma.ActivityTypeID
        WHERE ma.RepeatedFaultFlag = TRUE
        GROUP BY mj.VIN, at.ActivityType
     ) AS sub"
)->fetchColumn();
$totalRepeatPages = max(1, (int)ceil($totalRepeat / $perPage));
$repeatPage = min($repeatPage, $totalRepeatPages);
$repeatOffset = ($repeatPage - 1) * $perPage;

$repeated = $pdo->query(
    "SELECT mj.VIN, v.Model, at.ActivityType, COUNT(*) AS RepeatFaultCount
     FROM maintenanceactivity ma
     JOIN maintenancejob mj ON mj.JobID = ma.JobID
     JOIN vehicle v ON v.VIN = mj.VIN
     JOIN activitytype at ON at.ActivityTypeID = ma.ActivityTypeID
     WHERE ma.RepeatedFaultFlag = TRUE
     GROUP BY mj.VIN, v.Model, at.ActivityType
     ORDER BY RepeatFaultCount DESC
     LIMIT $perPage OFFSET $repeatOffset"
)->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Downtime &amp; Repeat Failures</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Vehicle Downtime</h2>
    <table>
        <tr><th>Vehicle</th><th>Depot</th><th>Jobs</th><th>Recorded (hrs)</th><th>In-Progress Est. (hrs)</th><th>Total (hrs)</th></tr>
        <?php foreach ($downtime as $d): ?>
            <tr>
                <td><?= htmlspecialchars($d['Manufacturer']) ?> <?= htmlspecialchars($d['Model']) ?> (<?= htmlspecialchars($d['VIN']) ?>)</td>
                <td><?= htmlspecialchars($d['DepotName']) ?></td>
                <td><?= htmlspecialchars($d['JobCount']) ?></td>
                <td><?= htmlspecialchars($d['RecordedDowntimeHours']) ?></td>
                <td><?= htmlspecialchars($d['InProgressEstimateHours']) ?></td>
                <td><?= htmlspecialchars($d['TotalDowntimeHours']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($downtimePage, $totalDowntimePages, 'downtime_page') ?>

    <h2>Vehicles with Repeated Component Failures</h2>
    <?php if (count($repeated) === 0): ?>
        <p>No repeated faults on record.</p>
    <?php else: ?>
        <table>
            <tr><th>Vehicle</th><th>Component / Activity Type</th><th>Repeat Count</th></tr>
            <?php foreach ($repeated as $r): ?>
                <tr>
                    <td><?= htmlspecialchars($r['Model']) ?> (<?= htmlspecialchars($r['VIN']) ?>)</td>
                    <td><?= htmlspecialchars($r['ActivityType']) ?></td>
                    <td class="score-warning"><?= htmlspecialchars($r['RepeatFaultCount']) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($repeatPage, $totalRepeatPages, 'repeat_page') ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
