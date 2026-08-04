<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Driver']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$driverId = $_SESSION['driver_id'];

$perPage = 10;
$page = currentPage('page');

$countStmt = $pdo->prepare('SELECT COUNT(*) FROM safetyevent WHERE DriverID = :id');
$countStmt->execute(['id' => $driverId]);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT se.EventID, se.EventTimestamp, v.RegistrationNumber, et.EventType,
            sev.SeverityLevel, se.ReviewState
     FROM safetyevent se
     JOIN vehicle v ON v.VIN = se.VIN
     JOIN eventtype et ON et.EventTypeID = se.EventTypeID
     JOIN eventseverity sev ON sev.SeverityID = se.SeverityID
     WHERE se.DriverID = :id
     ORDER BY se.EventTimestamp DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute(['id' => $driverId]);
$events = $stmt->fetchAll();

function severityClass(string $level): string
{
    return 'severity-' . strtolower($level);
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Safety Event History</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="driver_index.php">&larr; Back to dashboard</a>
    <h2>Safety Event History</h2>

    <?php if (count($events) === 0): ?>
        <p>No safety events on record.</p>
    <?php else: ?>
        <table>
            <tr>
                <th>Date</th>
                <th>Vehicle</th>
                <th>Event Type</th>
                <th>Severity</th>
                <th>Review Status</th>
            </tr>
            <?php foreach ($events as $e): ?>
                <tr>
                    <td><?= htmlspecialchars($e['EventTimestamp']) ?></td>
                    <td><?= htmlspecialchars($e['RegistrationNumber']) ?></td>
                    <td><?= htmlspecialchars($e['EventType']) ?></td>
                    <td class="<?= severityClass($e['SeverityLevel']) ?>"><?= htmlspecialchars($e['SeverityLevel']) ?></td>
                    <td><?= htmlspecialchars($e['ReviewState']) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($page, $totalPages, 'page') ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
