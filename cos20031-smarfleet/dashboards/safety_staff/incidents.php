<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Safety Staff']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$myStaffId = $_SESSION['review_staff_id'];
$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['start_review'])) {
            $stmt = $pdo->prepare(
                'INSERT INTO eventreview (EventID, ReviewerStaffID, Status, DateReviewed)
                 VALUES (:eventId, :staffId, \'Read\', NOW())'
            );
            $stmt->execute(['eventId' => $_POST['event_id'], 'staffId' => $myStaffId]);
            $message = 'Review started.';
        } elseif (isset($_POST['save_comments'])) {
            $stmt = $pdo->prepare(
                'UPDATE eventreview
                 SET Comments = :comments, Recommendations = :recommendations, Status = \'Commented\', DateReviewed = NOW()
                 WHERE ReviewID = :reviewId'
            );
            $stmt->execute([
                'comments' => $_POST['comments'],
                'recommendations' => $_POST['recommendations'],
                'reviewId' => $_POST['review_id'],
            ]);
            $message = 'Comments saved.';
        } elseif (isset($_POST['close_review'])) {
            $stmt = $pdo->prepare(
                'UPDATE eventreview SET Status = \'Closed\', DateReviewed = NOW() WHERE ReviewID = :reviewId'
            );
            $stmt->execute(['reviewId' => $_POST['review_id']]);
            $message = 'Review closed.';
        }
    } catch (PDOException $e) {
        $error = $e->getMessage();
    }
}

$driverId   = $_GET['driver_id'] ?? '';
$vin        = $_GET['vin'] ?? '';
$depotId    = $_GET['depot_id'] ?? '';
$eventTypeId = $_GET['event_type_id'] ?? '';
$severityId = $_GET['severity_id'] ?? '';
$reviewState = $_GET['review_state'] ?? '';
$dateFrom   = $_GET['date_from'] ?? '';
$dateTo     = $_GET['date_to'] ?? '';

$depots = $pdo->query('SELECT DepotID, DepotName FROM depot ORDER BY DepotName')->fetchAll();
$eventTypes = $pdo->query('SELECT EventTypeID, EventType FROM eventtype ORDER BY EventType')->fetchAll();
$severities = $pdo->query('SELECT SeverityID, SeverityLevel FROM eventseverity ORDER BY SeverityID')->fetchAll();

$perPage = 10;
$page = currentPage('page');

$whereClause = 'WHERE (:driverId = \'\' OR se.DriverID = :driverId)
          AND (:vin = \'\' OR se.VIN = :vin)
          AND (:depotId = \'\' OR se.DepotID = :depotId)
          AND (:eventTypeId = \'\' OR se.EventTypeID = :eventTypeId)
          AND (:severityId = \'\' OR se.SeverityID = :severityId)
          AND (:reviewState = \'\' OR se.ReviewState = :reviewState)
          AND (:dateFrom = \'\' OR se.EventTimestamp >= :dateFrom)
          AND (:dateTo = \'\' OR se.EventTimestamp <= :dateTo)';

$filterParams = [
    'driverId' => $driverId, 'vin' => $vin, 'depotId' => $depotId,
    'eventTypeId' => $eventTypeId, 'severityId' => $severityId,
    'reviewState' => $reviewState, 'dateFrom' => $dateFrom, 'dateTo' => $dateTo,
];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM safetyevent se $whereClause");
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$sql = "SELECT se.EventID, se.EventTimestamp, se.VIN, v.Model, d.DepotName, se.DriverID, dr.FullName AS DriverName,
               et.EventType, sev.SeverityLevel, se.Odometer, se.ReviewState,
               er.ReviewID, er.Status AS ReviewStatus, er.Comments, er.Recommendations, ss.FullName AS ReviewerName
        FROM safetyevent se
        JOIN vehicle v ON v.VIN = se.VIN
        JOIN depot d ON d.DepotID = se.DepotID
        JOIN driver dr ON dr.DriverID = se.DriverID
        JOIN eventtype et ON et.EventTypeID = se.EventTypeID
        JOIN eventseverity sev ON sev.SeverityID = se.SeverityID
        LEFT JOIN eventreview er ON er.EventID = se.EventID
        LEFT JOIN safetystaff ss ON ss.ReviewStaffID = er.ReviewerStaffID
        $whereClause
        ORDER BY se.EventTimestamp DESC
        LIMIT $perPage OFFSET $offset";

$stmt = $pdo->prepare($sql);
$stmt->execute($filterParams);
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
    <title>Incident Review</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="safety_staff_index.php">&larr; Back to dashboard</a>
    <h2>Incident Review</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <form method="GET">
        <input type="text" name="driver_id" placeholder="Driver ID" value="<?= htmlspecialchars($driverId) ?>">
        <input type="text" name="vin" placeholder="VIN" value="<?= htmlspecialchars($vin) ?>">
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
        <select name="review_state">
            <option value="">All Review States</option>
            <?php foreach (['Pending', 'Assigned', 'In Review', 'Completed', 'No Review Required'] as $state): ?>
                <option value="<?= $state ?>" <?= $reviewState === $state ? 'selected' : '' ?>><?= $state ?></option>
            <?php endforeach; ?>
        </select><br><br>
        From: <input type="date" name="date_from" value="<?= htmlspecialchars($dateFrom) ?>">
        To: <input type="date" name="date_to" value="<?= htmlspecialchars($dateTo) ?>">
        <button type="submit">Filter</button>
        <a href="incidents.php">Clear</a>
    </form>

    <p><?= htmlspecialchars($totalRows) ?> result(s)</p>

    <table>
        <tr>
            <th>Date</th><th>Driver</th><th>Vehicle</th><th>Depot</th><th>Event</th>
            <th>Severity</th><th>Review State</th><th>Review Actions</th>
        </tr>
        <?php foreach ($events as $e): ?>
            <tr>
                <td><?= htmlspecialchars($e['EventTimestamp']) ?></td>
                <td><?= htmlspecialchars($e['DriverName']) ?> (<?= htmlspecialchars($e['DriverID']) ?>)</td>
                <td><?= htmlspecialchars($e['Model']) ?> (<?= htmlspecialchars($e['VIN']) ?>)</td>
                <td><?= htmlspecialchars($e['DepotName']) ?></td>
                <td><?= htmlspecialchars($e['EventType']) ?></td>
                <td class="<?= severityClass($e['SeverityLevel']) ?>"><?= htmlspecialchars($e['SeverityLevel']) ?></td>
                <td><?= htmlspecialchars($e['ReviewState']) ?></td>
                <td>
                    <?php if ($e['ReviewID'] === null): ?>
                        <form method="POST">
                            <input type="hidden" name="event_id" value="<?= htmlspecialchars($e['EventID']) ?>">
                            <button type="submit" name="start_review" value="1">Start Review</button>
                        </form>
                    <?php elseif ($e['ReviewStatus'] !== 'Closed'): ?>
                        <details>
                            <summary>Reviewed by <?= htmlspecialchars($e['ReviewerName']) ?> (<?= htmlspecialchars($e['ReviewStatus']) ?>)</summary>
                            <form method="POST">
                                <input type="hidden" name="review_id" value="<?= htmlspecialchars($e['ReviewID']) ?>">
                                <textarea name="comments" placeholder="Comments"><?= htmlspecialchars($e['Comments'] ?? '') ?></textarea>
                                <textarea name="recommendations" placeholder="Recommendations"><?= htmlspecialchars($e['Recommendations'] ?? '') ?></textarea>
                                <button type="submit" name="save_comments" value="1">Save Comments</button>
                                <button type="submit" name="close_review" value="1">Close Review</button>
                            </form>
                        </details>
                    <?php else: ?>
                        Closed by <?= htmlspecialchars($e['ReviewerName']) ?>
                        <?php if ($e['Comments']): ?><br><em><?= htmlspecialchars($e['Comments']) ?></em><?php endif; ?>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>

    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
