<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$perPage = 10;
$depots = $pdo->query('SELECT DepotID, DepotName FROM depot ORDER BY DepotName')->fetchAll();
$manufacturers = $pdo->query('SELECT DISTINCT Manufacturer FROM vehicle ORDER BY Manufacturer')->fetchAll(PDO::FETCH_COLUMN);
$activityTypes = $pdo->query('SELECT ActivityTypeID, ActivityType FROM activitytype ORDER BY ActivityType')->fetchAll();

// --- Downtime (Q20) ---
$downtimePage = currentPage('downtime_page');
$downtimeDepot = $_GET['downtime_depot_id'] ?? '';
$downtimeManufacturer = $_GET['downtime_manufacturer'] ?? '';

$downtimeWhere = "WHERE (:depotId = '' OR d.DepotID = :depotId)
       AND (:manufacturer = '' OR v.Manufacturer = :manufacturer)";
$downtimeParams = ['depotId' => $downtimeDepot, 'manufacturer' => $downtimeManufacturer];

$totalDowntime = $pdo->prepare(
    "SELECT COUNT(*) FROM (
        SELECT v.VIN FROM maintenancejob mj JOIN vehicle v ON v.VIN = mj.VIN JOIN depot d ON d.DepotID = v.DepotID
        $downtimeWhere GROUP BY v.VIN
     ) AS sub"
);
$totalDowntime->execute($downtimeParams);
$totalDowntime = (int)$totalDowntime->fetchColumn();
$totalDowntimePages = max(1, (int)ceil($totalDowntime / $perPage));
$downtimePage = min($downtimePage, $totalDowntimePages);
$downtimeOffset = ($downtimePage - 1) * $perPage;

$downtimeStmt = $pdo->prepare(
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
     $downtimeWhere
     GROUP BY v.VIN, v.Model, v.Manufacturer, d.DepotName
     ORDER BY TotalDowntimeHours DESC
     LIMIT $perPage OFFSET $downtimeOffset"
);
$downtimeStmt->execute($downtimeParams);
$downtime = $downtimeStmt->fetchAll();

// --- Repeated component failures (Q23) ---
$repeatPage = currentPage('repeat_page');
$repeatVin = $_GET['repeat_vin'] ?? '';
$repeatActivityType = $_GET['repeat_activity_type_id'] ?? '';

$repeatWhere = "WHERE ma.RepeatedFaultFlag = TRUE
       AND (:vin = '' OR mj.VIN = :vin)
       AND (:activityTypeId = '' OR at.ActivityTypeID = :activityTypeId)";
$repeatParams = ['vin' => $repeatVin, 'activityTypeId' => $repeatActivityType];

$totalRepeat = $pdo->prepare(
    "SELECT COUNT(*) FROM (
        SELECT mj.VIN, at.ActivityType FROM maintenanceactivity ma
        JOIN maintenancejob mj ON mj.JobID = ma.JobID
        JOIN activitytype at ON at.ActivityTypeID = ma.ActivityTypeID
        $repeatWhere
        GROUP BY mj.VIN, at.ActivityType
     ) AS sub"
);
$totalRepeat->execute($repeatParams);
$totalRepeat = (int)$totalRepeat->fetchColumn();
$totalRepeatPages = max(1, (int)ceil($totalRepeat / $perPage));
$repeatPage = min($repeatPage, $totalRepeatPages);
$repeatOffset = ($repeatPage - 1) * $perPage;

$repeatStmt = $pdo->prepare(
    "SELECT mj.VIN, v.Model, at.ActivityType, COUNT(*) AS RepeatFaultCount
     FROM maintenanceactivity ma
     JOIN maintenancejob mj ON mj.JobID = ma.JobID
     JOIN vehicle v ON v.VIN = mj.VIN
     JOIN activitytype at ON at.ActivityTypeID = ma.ActivityTypeID
     $repeatWhere
     GROUP BY mj.VIN, v.Model, at.ActivityType
     ORDER BY RepeatFaultCount DESC
     LIMIT $perPage OFFSET $repeatOffset"
);
$repeatStmt->execute($repeatParams);
$repeated = $repeatStmt->fetchAll();
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
    <form method="GET">
        <input type="hidden" name="repeat_page" value="<?= $repeatPage ?>">
        <select name="downtime_depot_id">
            <option value="">All Depots</option>
            <?php foreach ($depots as $d): ?>
                <option value="<?= $d['DepotID'] ?>" <?= $downtimeDepot == $d['DepotID'] ? 'selected' : '' ?>><?= htmlspecialchars($d['DepotName']) ?></option>
            <?php endforeach; ?>
        </select>
        <select name="downtime_manufacturer">
            <option value="">All Manufacturers</option>
            <?php foreach ($manufacturers as $m): ?>
                <option value="<?= htmlspecialchars($m) ?>" <?= $downtimeManufacturer === $m ? 'selected' : '' ?>><?= htmlspecialchars($m) ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="vehicle_maintenance_report.php">Clear</a>
    </form>
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
    <form method="GET">
        <input type="hidden" name="downtime_page" value="<?= $downtimePage ?>">
        <input type="text" name="repeat_vin" placeholder="VIN" value="<?= htmlspecialchars($repeatVin) ?>">
        <select name="repeat_activity_type_id">
            <option value="">All Activity Types</option>
            <?php foreach ($activityTypes as $at): ?>
                <option value="<?= $at['ActivityTypeID'] ?>" <?= $repeatActivityType == $at['ActivityTypeID'] ? 'selected' : '' ?>><?= htmlspecialchars($at['ActivityType']) ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="vehicle_maintenance_report.php">Clear</a>
    </form>
    <?php if (count($repeated) === 0): ?>
        <p>No repeated faults matching this filter.</p>
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
