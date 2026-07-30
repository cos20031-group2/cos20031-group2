<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Safety Staff']);
require_once __DIR__ . '/../../config/db.php';

$depotId = $_GET['depot_id'] ?? '';
$eventTypeId = $_GET['event_type_id'] ?? '';
$severityId = $_GET['severity_id'] ?? '';

$depots = $pdo->query('SELECT DepotID, DepotName FROM depot ORDER BY DepotName')->fetchAll();
$eventTypes = $pdo->query('SELECT EventTypeID, EventType FROM eventtype ORDER BY EventType')->fetchAll();
$severities = $pdo->query('SELECT SeverityID, SeverityLevel FROM eventseverity ORDER BY SeverityID')->fetchAll();

$stmt = $pdo->prepare(
    'SELECT d.DepotName, YEAR(se.EventTimestamp) AS Yr, MONTH(se.EventTimestamp) AS Mo,
            et.EventType, sev.SeverityLevel, COUNT(*) AS EventCount
     FROM safetyevent se
     JOIN depot d ON d.DepotID = se.DepotID
     JOIN eventtype et ON et.EventTypeID = se.EventTypeID
     JOIN eventseverity sev ON sev.SeverityID = se.SeverityID
     WHERE (:depotId = \'\' OR se.DepotID = :depotId)
       AND (:eventTypeId = \'\' OR se.EventTypeID = :eventTypeId)
       AND (:severityId = \'\' OR se.SeverityID = :severityId)
     GROUP BY d.DepotName, YEAR(se.EventTimestamp), MONTH(se.EventTimestamp), et.EventType, sev.SeverityLevel
     ORDER BY d.DepotName, Yr, Mo, et.EventType, sev.SeverityLevel'
);
$stmt->execute(['depotId' => $depotId, 'eventTypeId' => $eventTypeId, 'severityId' => $severityId]);
$trends = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Depot Safety Trends</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="safety_staff_index.php">&larr; Back to dashboard</a>
    <h2>Depot Safety Trends</h2>

    <form method="GET">
        <select name="depot_id">
            <option value="">All Depots</option>
            <?php foreach ($depots as $d): ?>
                <option value="<?= $d['DepotID'] ?>" <?= $depotId == $d['DepotID'] ? 'selected' : '' ?>><?= htmlspecialchars($d['DepotName']) ?></option>
            <?php endforeach; ?>
        </select>
        <select name="event_type_id">
            <option value="">All Event Types</option>
            <?php foreach ($eventTypes as $et): ?>
                <option value="<?= $et['EventTypeID'] ?>" <?= $eventTypeId == $et['EventTypeID'] ? 'selected' : '' ?>><?= htmlspecialchars($et['EventType']) ?></option>
            <?php endforeach; ?>
        </select>
        <select name="severity_id">
            <option value="">All Severities</option>
            <?php foreach ($severities as $s): ?>
                <option value="<?= $s['SeverityID'] ?>" <?= $severityId == $s['SeverityID'] ? 'selected' : '' ?>><?= htmlspecialchars($s['SeverityLevel']) ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="depot_trends.php">Clear</a>
    </form>

    <table>
        <tr><th>Depot</th><th>Year</th><th>Month</th><th>Event Type</th><th>Severity</th><th>Count</th></tr>
        <?php foreach ($trends as $t): ?>
            <tr>
                <td><?= htmlspecialchars($t['DepotName']) ?></td>
                <td><?= htmlspecialchars($t['Yr']) ?></td>
                <td><?= htmlspecialchars($t['Mo']) ?></td>
                <td><?= htmlspecialchars($t['EventType']) ?></td>
                <td><?= htmlspecialchars($t['SeverityLevel']) ?></td>
                <td><?= htmlspecialchars($t['EventCount']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
