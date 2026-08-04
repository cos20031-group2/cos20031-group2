<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Mechanic']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';
require_once __DIR__ . '/../../includes/pagination.php';

$mechanicId = $_SESSION['mechanic_id'];
$message = '';
$error = '';

// Handle starting a new work session
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['start_session'])) {
    $activityId = $_POST['activity_id'] ?? '';

    try {
        $stmt = $pdo->prepare(
            'INSERT INTO mechanicworksession (MechanicID, ActivityID, StartTime)
             VALUES (:mechanicId, :activityId, NOW())'
        );
        $stmt->execute(['mechanicId' => $mechanicId, 'activityId' => $activityId]);
        $message = 'Work session started.';
    } catch (PDOException $e) {
        // Surfaces the trigger's SIGNAL message (e.g. missing certification)
        // rather than a raw stack trace.
        $error = friendlySqlError($e);
    }
}

// Handle closing an open work session
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['close_session'])) {
    $sessionId = $_POST['session_id'] ?? '';

    try {
        $stmt = $pdo->prepare(
            'UPDATE mechanicworksession
             SET EndTime = NOW()
             WHERE SessionID = :sessionId AND MechanicID = :mechanicId AND EndTime IS NULL'
        );
        $stmt->execute(['sessionId' => $sessionId, 'mechanicId' => $mechanicId]);
        $message = 'Work session closed.';
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

// Activities this mechanic is certified for, on jobs still open at their own workshop
$stmt = $pdo->prepare(
    'SELECT ma.ActivityID, mj.JobID, v.RegistrationNumber, at.ActivityType
     FROM maintenanceactivity ma
     JOIN maintenancejob mj ON mj.JobID = ma.JobID
     JOIN vehicle v ON v.VIN = mj.VIN
     JOIN activitytype at ON at.ActivityTypeID = ma.ActivityTypeID
     JOIN mechanic m ON m.MechanicID = :mechanicId
     WHERE mj.WorkshopID = m.WorkshopID
       AND mj.DateClosed IS NULL
       AND EXISTS (
           SELECT 1 FROM mechaniccertification mc
           WHERE mc.MechanicID = :mechanicId
             AND mc.MechanicCertificationTypeID = at.RequiredMechanicCertification
             AND mc.Status IN (\'Active\', \'Reinstated\')
             AND mc.ExpiryDate > CURDATE()
       )
     ORDER BY mj.DateOpened DESC'
);
$stmt->execute(['mechanicId' => $mechanicId]);
$availableActivities = $stmt->fetchAll();

// This mechanic's full work session history
$perPage = 10;
$page = currentPage('page');

$countStmt = $pdo->prepare('SELECT COUNT(*) FROM mechanicworksession WHERE MechanicID = :mechanicId');
$countStmt->execute(['mechanicId' => $mechanicId]);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT mws.SessionID, mws.StartTime, mws.EndTime, mj.JobID, v.RegistrationNumber, at.ActivityType
     FROM mechanicworksession mws
     JOIN maintenanceactivity ma ON ma.ActivityID = mws.ActivityID
     JOIN maintenancejob mj ON mj.JobID = ma.JobID
     JOIN vehicle v ON v.VIN = mj.VIN
     JOIN activitytype at ON at.ActivityTypeID = ma.ActivityTypeID
     WHERE mws.MechanicID = :mechanicId
     ORDER BY mws.StartTime DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute(['mechanicId' => $mechanicId]);
$sessions = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Work Sessions</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="mechanic_index.php">&larr; Back to dashboard</a>
    <h2>Work Sessions</h2>

    <?php if ($message !== ''): ?>
        <p class="score-good"><?= htmlspecialchars($message) ?></p>
    <?php endif; ?>
    <?php if ($error !== ''): ?>
        <p class="score-critical"><?= htmlspecialchars($error) ?></p>
    <?php endif; ?>

    <h3>Start a New Work Session</h3>
    <?php if (count($availableActivities) === 0): ?>
        <p>No open activities at your workshop match your current certifications.</p>
    <?php else: ?>
        <form method="POST">
            <select name="activity_id" required>
                <option value="">-- Select an activity --</option>
                <?php foreach ($availableActivities as $a): ?>
                    <option value="<?= htmlspecialchars($a['ActivityID']) ?>">
                        <?= htmlspecialchars($a['JobID']) ?> -
                        <?= htmlspecialchars($a['RegistrationNumber']) ?> -
                        <?= htmlspecialchars($a['ActivityType']) ?>
                    </option>
                <?php endforeach; ?>
            </select>
            <button type="submit" name="start_session" value="1">Start Session</button>
        </form>
    <?php endif; ?>

    <h3>My Work Sessions</h3>
    <?php if (count($sessions) === 0): ?>
        <p>No work sessions logged yet.</p>
    <?php else: ?>
        <table>
            <tr>
                <th>Job</th>
                <th>Vehicle</th>
                <th>Activity Type</th>
                <th>Start</th>
                <th>End</th>
                <th></th>
            </tr>
            <?php foreach ($sessions as $s): ?>
                <tr>
                    <td><?= htmlspecialchars($s['JobID']) ?></td>
                    <td><?= htmlspecialchars($s['RegistrationNumber']) ?></td>
                    <td><?= htmlspecialchars($s['ActivityType']) ?></td>
                    <td><?= htmlspecialchars($s['StartTime']) ?></td>
                    <td><?= htmlspecialchars($s['EndTime'] ?? 'In progress') ?></td>
                    <td>
                        <?php if ($s['EndTime'] === null): ?>
                            <form method="POST" style="display:inline;">
                                <input type="hidden" name="session_id" value="<?= htmlspecialchars($s['SessionID']) ?>">
                                <button type="submit" name="close_session" value="1">Close</button>
                            </form>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($page, $totalPages, 'page') ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
