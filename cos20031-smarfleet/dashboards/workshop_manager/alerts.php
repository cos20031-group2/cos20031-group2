<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';
require_once __DIR__ . '/../../includes/pagination.php';

$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_alert'])) {
    $newStatus = $_POST['new_status'];
    try {
        if ($newStatus === 'Resolved') {
            $stmt = $pdo->prepare(
                'UPDATE predictivealert SET AlertStatus = :status, ActionTaken = :action, ResolutionDate = NOW()
                 WHERE AlertID = :id'
            );
        } else {
            $stmt = $pdo->prepare(
                'UPDATE predictivealert SET AlertStatus = :status, ActionTaken = :action, ResolutionDate = NULL
                 WHERE AlertID = :id'
            );
        }
        $stmt->execute(['status' => $newStatus, 'action' => $_POST['action_taken'], 'id' => $_POST['alert_id']]);
        $message = 'Alert updated.';
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$statusFilter = $_GET['status'] ?? '';
$perPage = 10;
$page = currentPage('page');

$whereClause = "WHERE (:status = '' OR pa.AlertStatus = :status)";
$filterParams = ['status' => $statusFilter];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM predictivealert pa $whereClause");
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT pa.AlertID, pa.VIN, v.Model, v.Manufacturer, at.AlertType, pa.DateGenerated,
            pa.AlertStatus, pa.ActionTaken, pa.ResolutionDate
     FROM predictivealert pa
     JOIN vehicle v ON v.VIN = pa.VIN
     JOIN alerttype at ON at.AlertTypeID = pa.AlertTypeID
     $whereClause
     ORDER BY pa.DateGenerated DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$alerts = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Predictive Alerts</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Predictive Maintenance Alerts</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <form method="GET">
        <select name="status">
            <option value="">All Statuses</option>
            <?php foreach (['Unresolved', 'Acknowledged', 'Scheduled For Inspection', 'Urgent Repair Standby', 'Resolved'] as $s): ?>
                <option value="<?= $s ?>" <?= $statusFilter === $s ? 'selected' : '' ?>><?= $s ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="alerts.php">Clear</a>
    </form>

    <p><em>Escalating to "Scheduled For Inspection" or "Urgent Repair Standby" automatically creates a ScheduledService entry for the vehicle.</em></p>

    <table>
        <tr><th>Date</th><th>Vehicle</th><th>Alert Type</th><th>Status</th><th>Action Taken</th><th>Update</th></tr>
        <?php foreach ($alerts as $a): ?>
            <tr>
                <td><?= htmlspecialchars($a['DateGenerated']) ?></td>
                <td><?= htmlspecialchars($a['Manufacturer']) ?> <?= htmlspecialchars($a['Model']) ?> (<?= htmlspecialchars($a['VIN']) ?>)</td>
                <td><?= htmlspecialchars($a['AlertType']) ?></td>
                <td class="<?= $a['AlertStatus'] === 'Urgent Repair Standby' ? 'score-critical' : '' ?>"><?= htmlspecialchars($a['AlertStatus']) ?></td>
                <td><?= htmlspecialchars($a['ActionTaken'] ?? '') ?></td>
                <td>
                    <?php if ($a['AlertStatus'] !== 'Resolved'): ?>
                        <details>
                            <summary>Update</summary>
                            <form method="POST">
                                <input type="hidden" name="alert_id" value="<?= htmlspecialchars($a['AlertID']) ?>">
                                <select name="new_status">
                                    <option value="Acknowledged">Acknowledge (continue monitoring)</option>
                                    <option value="Scheduled For Inspection">Schedule Inspection/Service</option>
                                    <option value="Urgent Repair Standby">Escalate -- Urgent Repair</option>
                                    <option value="Resolved">Mark Resolved</option>
                                </select>
                                <input type="text" name="action_taken" placeholder="Notes on action taken" value="<?= htmlspecialchars($a['ActionTaken'] ?? '') ?>">
                                <button type="submit" name="update_alert" value="1">Save</button>
                            </form>
                        </details>
                    <?php else: ?>
                        Resolved <?= htmlspecialchars($a['ResolutionDate']) ?>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
