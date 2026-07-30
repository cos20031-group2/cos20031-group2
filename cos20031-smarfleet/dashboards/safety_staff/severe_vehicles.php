<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Safety Staff']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$vin = $_GET['vin'] ?? '';
$severityId = $_GET['severity_id'] ?? '';

$severities = $pdo->query('SELECT SeverityID, SeverityLevel FROM eventseverity ORDER BY SeverityID')->fetchAll();

$perPage = 10;
$page = currentPage('page');

$whereClause = "WHERE sev.SeverityLevel IN ('High', 'Critical')
       AND (:vin = '' OR se.VIN = :vin)
       AND (:severityId = '' OR se.SeverityID = :severityId)";
$filterParams = ['vin' => $vin, 'severityId' => $severityId];

$countStmt = $pdo->prepare(
    "SELECT COUNT(*) FROM (
        SELECT v.VIN, et.EventType, sev.SeverityLevel
        FROM safetyevent se
        JOIN vehicle v ON v.VIN = se.VIN
        JOIN eventtype et ON et.EventTypeID = se.EventTypeID
        JOIN eventseverity sev ON sev.SeverityID = se.SeverityID
        $whereClause
        GROUP BY v.VIN, et.EventType, sev.SeverityLevel
     ) AS sub"
);
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT v.VIN, v.Model, v.Manufacturer, et.EventType, sev.SeverityLevel, COUNT(*) AS EventCount
     FROM safetyevent se
     JOIN vehicle v ON v.VIN = se.VIN
     JOIN eventtype et ON et.EventTypeID = se.EventTypeID
     JOIN eventseverity sev ON sev.SeverityID = se.SeverityID
     $whereClause
     GROUP BY v.VIN, v.Model, v.Manufacturer, et.EventType, sev.SeverityLevel
     ORDER BY EventCount DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$results = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Vehicles with Severe Incidents</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="safety_staff_index.php">&larr; Back to dashboard</a>
    <h2>Vehicles Associated with Severe Incidents</h2>

    <form method="GET">
        <input type="text" name="vin" placeholder="VIN" value="<?= htmlspecialchars($vin) ?>">
        <select name="severity_id">
            <option value="">High &amp; Critical</option>
            <?php foreach ($severities as $s): ?>
                <?php if (in_array($s['SeverityLevel'], ['High', 'Critical'], true)): ?>
                    <option value="<?= $s['SeverityID'] ?>" <?= $severityId == $s['SeverityID'] ? 'selected' : '' ?>><?= htmlspecialchars($s['SeverityLevel']) ?> only</option>
                <?php endif; ?>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="severe_vehicles.php">Clear</a>
    </form>

    <table>
        <tr><th>Vehicle</th><th>Manufacturer</th><th>Event Type</th><th>Severity</th><th>Count</th></tr>
        <?php foreach ($results as $r): ?>
            <tr>
                <td><?= htmlspecialchars($r['Model']) ?> (<?= htmlspecialchars($r['VIN']) ?>)</td>
                <td><?= htmlspecialchars($r['Manufacturer']) ?></td>
                <td><?= htmlspecialchars($r['EventType']) ?></td>
                <td class="severity-<?= strtolower($r['SeverityLevel']) ?>"><?= htmlspecialchars($r['SeverityLevel']) ?></td>
                <td><?= htmlspecialchars($r['EventCount']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
