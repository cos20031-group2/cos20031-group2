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
$vin = $_GET['vin'] ?? '';
$alertTypeId = $_GET['alert_type_id'] ?? '';
$depotId = $_GET['depot_id'] ?? '';
$dateFrom = $_GET['date_from'] ?? '';
$dateTo = $_GET['date_to'] ?? '';

$alertTypes = $pdo->query('SELECT AlertTypeID, AlertType FROM alerttype ORDER BY AlertType')->fetchAll();
$depots = $pdo->query('SELECT DepotID, DepotName FROM depot ORDER BY DepotName')->fetchAll();

$perPage = 10;
$page = currentPage('page');

$whereClause = "WHERE (:status = '' OR pa.AlertStatus = :status)
       AND (:vin = '' OR pa.VIN = :vin)
       AND (:alertTypeId = '' OR pa.AlertTypeID = :alertTypeId)
       AND (:depotId = '' OR v.DepotID = :depotId)
       AND (:dateFrom = '' OR pa.DateGenerated >= :dateFrom)
       AND (:dateTo = '' OR pa.DateGenerated <= :dateTo)";
$filterParams = [
    'status' => $statusFilter, 'vin' => $vin, 'alertTypeId' => $alertTypeId,
    'depotId' => $depotId, 'dateFrom' => $dateFrom, 'dateTo' => $dateTo,
];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM predictivealert pa JOIN vehicle v ON v.VIN = pa.VIN $whereClause");
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT pa.AlertID, pa.VIN, v.Model, v.Manufacturer, v.RegistrationNumber, at.AlertType, pa.DateGenerated,
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
        <input type="text" name="vin" placeholder="VIN" value="<?= htmlspecialchars($vin) ?>">
        <select name="alert_type_id">
            <option value="">All Alert Types</option>
            <?php foreach ($alertTypes as $at): ?>
                <option value="<?= $at['AlertTypeID'] ?>" <?= $alertTypeId == $at['AlertTypeID'] ? 'selected' : '' ?>><?= htmlspecialchars($at['AlertType']) ?></option>
            <?php endforeach; ?>
        </select>
        <select name="depot_id">
            <option value="">All Depots</option>
            <?php foreach ($depots as $d): ?>
                <option value="<?= $d['DepotID'] ?>" <?= $depotId == $d['DepotID'] ? 'selected' : '' ?>><?= htmlspecialchars($d['DepotName']) ?></option>
            <?php endforeach; ?>
        </select><br><br>
        From: <input type="date" name="date_from" value="<?= htmlspecialchars($dateFrom) ?>">
        To: <input type="date" name="date_to" value="<?= htmlspecialchars($dateTo) ?>">
        <button type="submit">Filter</button>
        <a href="alerts.php">Clear</a>
    </form>

    <p><?= htmlspecialchars($totalRows) ?> alert(s)</p>
    <p><em>Escalating to "Scheduled For Inspection" or "Urgent Repair Standby" automatically creates a ScheduledService entry for the vehicle.</em></p>

    <table>
        <tr><th>Date</th><th>Vehicle</th><th>Alert Type</th><th>Status</th><th>Action Taken</th><th>Update</th></tr>
        <?php foreach ($alerts as $a): ?>
            <tr>
                <td><?= htmlspecialchars($a['DateGenerated']) ?></td>
                <td><?= htmlspecialchars($a['Manufacturer']) ?> <?= htmlspecialchars($a['Model']) ?> (<?= htmlspecialchars($a['RegistrationNumber']) ?>)</td>
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
