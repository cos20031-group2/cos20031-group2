<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';
require_once __DIR__ . '/../../includes/pagination.php';

$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['create_schedule'])) {
            $stmt = $pdo->prepare(
                "INSERT INTO scheduledservice (VIN, ScheduledDate, Reason, Status)
                 VALUES (:vin, :date, :reason, 'Scheduled')"
            );
            $stmt->execute(['vin' => $_POST['vin'], 'date' => $_POST['scheduled_date'], 'reason' => $_POST['reason']]);
            $message = 'Service scheduled.';
        } elseif (isset($_POST['start_schedule'])) {
            $stmt = $pdo->prepare(
                "UPDATE scheduledservice SET Status = 'In Progress' WHERE ScheduleID = :id AND Status = 'Scheduled'"
            );
            $stmt->execute(['id' => $_POST['schedule_id']]);
            $message = 'Marked In Progress.';
        } elseif (isset($_POST['complete_schedule'])) {
            $stmt = $pdo->prepare(
                "UPDATE scheduledservice SET Status = 'Completed', CompletionDate = CURDATE()
                 WHERE ScheduleID = :id AND Status IN ('Scheduled', 'In Progress')"
            );
            $stmt->execute(['id' => $_POST['schedule_id']]);
            $message = 'Marked Completed.';
        } elseif (isset($_POST['cancel_schedule'])) {
            $stmt = $pdo->prepare(
                "UPDATE scheduledservice SET Status = 'Cancelled' WHERE ScheduleID = :id AND Status IN ('Scheduled', 'In Progress')"
            );
            $stmt->execute(['id' => $_POST['schedule_id']]);
            $message = 'Cancelled.';
        }
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$perPage = 10;

// Q22: overdue services
$overduePage = currentPage('overdue_page');
$totalOverdue = (int)$pdo->query(
    "SELECT COUNT(*) FROM scheduledservice WHERE Status IN ('Scheduled', 'In Progress') AND ScheduledDate <= CURDATE()"
)->fetchColumn();
$totalOverduePages = max(1, (int)ceil($totalOverdue / $perPage));
$overduePage = min($overduePage, $totalOverduePages);
$overdueOffset = ($overduePage - 1) * $perPage;

$overdue = $pdo->query(
    "SELECT ss.ScheduleID, ss.VIN, v.RegistrationNumber, ss.ScheduledDate, ss.Status, ss.Reason,
            DATEDIFF(CURDATE(), ss.ScheduledDate) AS DaysOverdue
     FROM scheduledservice ss
     JOIN vehicle v ON v.VIN = ss.VIN
     WHERE ss.Status IN ('Scheduled', 'In Progress') AND ss.ScheduledDate <= CURDATE()
     ORDER BY DaysOverdue DESC
     LIMIT $perPage OFFSET $overdueOffset"
)->fetchAll();

// Q25: vehicles awaiting inspection
$awaitingPage = currentPage('awaiting_page');
$totalAwaiting = (int)$pdo->query(
    "SELECT COUNT(*) FROM vehicle v JOIN vehiclestatus vs ON vs.VehicleStatusID = v.OperationalStatus WHERE vs.VehicleStatus = 'Awaiting Inspection'"
)->fetchColumn();
$totalAwaitingPages = max(1, (int)ceil($totalAwaiting / $perPage));
$awaitingPage = min($awaitingPage, $totalAwaitingPages);
$awaitingOffset = ($awaitingPage - 1) * $perPage;

$awaiting = $pdo->query(
    "SELECT v.VIN, v.Model, v.Manufacturer, d.DepotName, v.Odometer
     FROM vehicle v
     JOIN vehiclestatus vs ON vs.VehicleStatusID = v.OperationalStatus
     JOIN depot d ON d.DepotID = v.DepotID
     WHERE vs.VehicleStatus = 'Awaiting Inspection'
     LIMIT $perPage OFFSET $awaitingOffset"
)->fetchAll();

// All schedules (for general management)
$allPage = currentPage('all_page');
$statusFilter = $_GET['status'] ?? '';
$whereClause = "WHERE (:status = '' OR ss.Status = :status)";
$filterParams = ['status' => $statusFilter];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM scheduledservice ss $whereClause");
$countStmt->execute($filterParams);
$totalAll = (int)$countStmt->fetchColumn();
$totalAllPages = max(1, (int)ceil($totalAll / $perPage));
$allPage = min($allPage, $totalAllPages);
$allOffset = ($allPage - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT ss.ScheduleID, ss.VIN, v.RegistrationNumber, ss.ScheduledDate, ss.CompletionDate, ss.Status, ss.Reason
     FROM scheduledservice ss JOIN vehicle v ON v.VIN = ss.VIN
     $whereClause
     ORDER BY ss.ScheduledDate DESC
     LIMIT $perPage OFFSET $allOffset"
);
$stmt->execute($filterParams);
$allSchedules = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Scheduled Services</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Scheduled Services</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <h3>Schedule a Service</h3>
    <form method="POST">
        VIN: <input type="text" name="vin" maxlength="17" placeholder="17-character VIN" required>
        Date: <input type="date" name="scheduled_date" required>
        Reason: <input type="text" name="reason">
        <button type="submit" name="create_schedule" value="1">Schedule</button>
    </form>

    <h3>Overdue Services</h3>
    <?php if (count($overdue) === 0): ?>
        <p>No overdue services.</p>
    <?php else: ?>
        <table>
            <tr><th>Vehicle</th><th>Scheduled Date</th><th>Days Overdue</th><th>Status</th><th>Reason</th><th>Actions</th></tr>
            <?php foreach ($overdue as $o): ?>
                <tr>
                    <td><?= htmlspecialchars($o['RegistrationNumber']) ?></td>
                    <td><?= htmlspecialchars($o['ScheduledDate']) ?></td>
                    <td class="score-critical"><?= htmlspecialchars($o['DaysOverdue']) ?></td>
                    <td><?= htmlspecialchars($o['Status']) ?></td>
                    <td><?= htmlspecialchars($o['Reason']) ?></td>
                    <td>
                        <?php if ($o['Status'] === 'Scheduled'): ?>
                            <form method="POST" style="display:inline;">
                                <input type="hidden" name="schedule_id" value="<?= $o['ScheduleID'] ?>">
                                <button type="submit" name="start_schedule" value="1">Start</button>
                            </form>
                        <?php endif; ?>
                        <form method="POST" style="display:inline;">
                            <input type="hidden" name="schedule_id" value="<?= $o['ScheduleID'] ?>">
                            <button type="submit" name="complete_schedule" value="1">Complete</button>
                        </form>
                        <form method="POST" style="display:inline;">
                            <input type="hidden" name="schedule_id" value="<?= $o['ScheduleID'] ?>">
                            <button type="submit" name="cancel_schedule" value="1">Cancel</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($overduePage, $totalOverduePages, 'overdue_page') ?>
    <?php endif; ?>

    <h3>Vehicles Awaiting Inspection</h3>
    <?php if (count($awaiting) === 0): ?>
        <p>No vehicles currently awaiting inspection.</p>
    <?php else: ?>
        <table>
            <tr><th>Vehicle</th><th>Depot</th><th>Odometer</th></tr>
            <?php foreach ($awaiting as $a): ?>
                <tr>
                    <td><?= htmlspecialchars($a['Manufacturer']) ?> <?= htmlspecialchars($a['Model']) ?> (<?= htmlspecialchars($a['VIN']) ?>)</td>
                    <td><?= htmlspecialchars($a['DepotName']) ?></td>
                    <td><?= htmlspecialchars($a['Odometer']) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($awaitingPage, $totalAwaitingPages, 'awaiting_page') ?>
    <?php endif; ?>

    <h3>All Scheduled Services</h3>
    <form method="GET">
        <select name="status">
            <option value="">All Statuses</option>
            <?php foreach (['Scheduled', 'In Progress', 'Completed', 'Cancelled'] as $s): ?>
                <option value="<?= $s ?>" <?= $statusFilter === $s ? 'selected' : '' ?>><?= $s ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="scheduled_services.php">Clear</a>
    </form>
    <table>
        <tr><th>Vehicle</th><th>Scheduled</th><th>Completed</th><th>Status</th><th>Reason</th></tr>
        <?php foreach ($allSchedules as $s): ?>
            <tr>
                <td><?= htmlspecialchars($s['RegistrationNumber']) ?></td>
                <td><?= htmlspecialchars($s['ScheduledDate']) ?></td>
                <td><?= htmlspecialchars($s['CompletionDate'] ?? '') ?></td>
                <td><?= htmlspecialchars($s['Status']) ?></td>
                <td><?= htmlspecialchars($s['Reason']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($allPage, $totalAllPages, 'all_page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
