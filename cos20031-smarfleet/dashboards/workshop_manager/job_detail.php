<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';

$jobId = $_GET['job'] ?? '';
$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['add_activity'])) {
            $stmt = $pdo->prepare(
                'INSERT INTO maintenanceactivity (JobID, ActivityTypeID, DiagnosticResult, RepeatedFaultFlag, WarrantyFlag, LinkedAlertID)
                 VALUES (:jobId, :typeId, :diagnostic, :repeated, :warranty, :alertId)'
            );
            $stmt->execute([
                'jobId' => $jobId, 'typeId' => $_POST['activity_type_id'], 'diagnostic' => $_POST['diagnostic_result'],
                'repeated' => isset($_POST['repeated_fault']) ? 1 : 0, 'warranty' => isset($_POST['warranty']) ? 1 : 0,
                'alertId' => $_POST['linked_alert_id'] !== '' ? $_POST['linked_alert_id'] : null,
            ]);
            $message = 'Activity added.';
        } elseif (isset($_POST['add_part'])) {
            $partStmt = $pdo->prepare('SELECT UnitPrice FROM part WHERE PartNumber = :pn');
            $partStmt->execute(['pn' => $_POST['part_number']]);
            $unitPrice = $partStmt->fetchColumn();

            $stmt = $pdo->prepare(
                'INSERT INTO activitypart (ActivityID, PartNumber, QuantityUsed, UnitCost)
                 VALUES (:activityId, :partNumber, :quantity, :unitCost)'
            );
            $stmt->execute([
                'activityId' => $_POST['activity_id'], 'partNumber' => $_POST['part_number'],
                'quantity' => $_POST['quantity_used'], 'unitCost' => $unitPrice,
            ]);
            $message = 'Part usage recorded.';
        }
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$jobStmt = $pdo->prepare(
    'SELECT mj.*, v.RegistrationNumber, v.Model, v.Manufacturer, w.Name AS WorkshopName
     FROM maintenancejob mj
     JOIN vehicle v ON v.VIN = mj.VIN
     JOIN workshop w ON w.WorkshopID = mj.WorkshopID
     WHERE mj.JobID = :id'
);
$jobStmt->execute(['id' => $jobId]);
$job = $jobStmt->fetch();

if (!$job) {
    die('Job not found.');
}

$activityTypes = $pdo->query('SELECT ActivityTypeID, ActivityType FROM activitytype ORDER BY ActivityType')->fetchAll();
$vehicleAlerts = $pdo->prepare(
    "SELECT AlertID, DateGenerated FROM predictivealert WHERE VIN = :vin AND AlertStatus <> 'Resolved' ORDER BY DateGenerated DESC"
);
$vehicleAlerts->execute(['vin' => $job['VIN']]);
$vehicleAlerts = $vehicleAlerts->fetchAll();

$parts = $pdo->query('SELECT PartNumber, PartName, CurrentStock, UnitPrice FROM part ORDER BY PartName')->fetchAll();

$activitiesStmt = $pdo->prepare(
    'SELECT ma.ActivityID, at.ActivityType, ma.DiagnosticResult, ma.RepeatedFaultFlag, ma.WarrantyFlag,
            pa.AlertID, aty.AlertType AS LinkedAlertType
     FROM maintenanceactivity ma
     JOIN activitytype at ON at.ActivityTypeID = ma.ActivityTypeID
     LEFT JOIN predictivealert pa ON pa.AlertID = ma.LinkedAlertID
     LEFT JOIN alerttype aty ON aty.AlertTypeID = pa.AlertTypeID
     WHERE ma.JobID = :id
     ORDER BY ma.ActivityID'
);
$activitiesStmt->execute(['id' => $jobId]);
$activities = $activitiesStmt->fetchAll();

foreach ($activities as &$act) {
    $partsStmt = $pdo->prepare(
        'SELECT ap.PartNumber, p.PartName, ap.QuantityUsed, ap.UnitCost
         FROM activitypart ap JOIN part p ON p.PartNumber = ap.PartNumber
         WHERE ap.ActivityID = :id'
    );
    $partsStmt->execute(['id' => $act['ActivityID']]);
    $act['parts'] = $partsStmt->fetchAll();

    $sessionsStmt = $pdo->prepare(
        'SELECT m.FullName, mws.StartTime, mws.EndTime
         FROM mechanicworksession mws JOIN mechanic m ON m.MechanicID = mws.MechanicID
         WHERE mws.ActivityID = :id ORDER BY mws.StartTime'
    );
    $sessionsStmt->execute(['id' => $act['ActivityID']]);
    $act['sessions'] = $sessionsStmt->fetchAll();
}
unset($act);
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Job <?= htmlspecialchars($jobId) ?></title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="jobs.php">&larr; Back to jobs</a>
    <h2>Job <?= htmlspecialchars($job['JobID']) ?></h2>
    <p>
        <?= htmlspecialchars($job['Manufacturer']) ?> <?= htmlspecialchars($job['Model']) ?> (<?= htmlspecialchars($job['RegistrationNumber']) ?>)
        &nbsp;|&nbsp; Workshop: <?= htmlspecialchars($job['WorkshopName']) ?>
        &nbsp;|&nbsp; Opened: <?= htmlspecialchars($job['DateOpened']) ?>
        &nbsp;|&nbsp; Status: <?= $job['DateClosed'] ? 'Closed (' . htmlspecialchars($job['DateClosed']) . ')' : 'Open' ?>
    </p>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <?php if (!$job['DateClosed']): ?>
        <h3>Add Activity</h3>
        <form method="POST">
            <select name="activity_type_id" required>
                <?php foreach ($activityTypes as $t): ?>
                    <option value="<?= $t['ActivityTypeID'] ?>"><?= htmlspecialchars($t['ActivityType']) ?></option>
                <?php endforeach; ?>
            </select>
            Diagnostic Result: <input type="text" name="diagnostic_result">
            <label><input type="checkbox" name="repeated_fault"> Repeated Fault</label>
            <label><input type="checkbox" name="warranty"> Warranty</label>
            Linked Alert (optional):
            <select name="linked_alert_id">
                <option value="">-- None --</option>
                <?php foreach ($vehicleAlerts as $va): ?>
                    <option value="<?= $va['AlertID'] ?>">Alert #<?= $va['AlertID'] ?> (<?= htmlspecialchars($va['DateGenerated']) ?>)</option>
                <?php endforeach; ?>
            </select>
            <button type="submit" name="add_activity" value="1">Add Activity</button>
        </form>
    <?php endif; ?>

    <h3>Activities</h3>
    <?php if (count($activities) === 0): ?>
        <p>No activities recorded yet.</p>
    <?php endif; ?>
    <?php foreach ($activities as $act): ?>
        <div class="card" style="margin-bottom:16px;">
            <h4>Activity #<?= htmlspecialchars($act['ActivityID']) ?> -- <?= htmlspecialchars($act['ActivityType']) ?></h4>
            <p>
                Diagnostic: <?= htmlspecialchars($act['DiagnosticResult'] ?? '') ?><br>
                Repeated Fault: <?= $act['RepeatedFaultFlag'] ? 'Yes' : 'No' ?> &nbsp;|&nbsp;
                Warranty: <?= $act['WarrantyFlag'] ? 'Yes' : 'No' ?>
                <?php if ($act['LinkedAlertType']): ?> &nbsp;|&nbsp; Linked Alert: <?= htmlspecialchars($act['LinkedAlertType']) ?><?php endif; ?>
            </p>

            <strong>Parts Used</strong>
            <table>
                <tr><th>Part</th><th>Qty</th><th>Unit Cost</th></tr>
                <?php foreach ($act['parts'] as $p): ?>
                    <tr>
                        <td><?= htmlspecialchars($p['PartName']) ?></td>
                        <td><?= htmlspecialchars($p['QuantityUsed']) ?></td>
                        <td><?= number_format($p['UnitCost']) ?> VND</td>
                    </tr>
                <?php endforeach; ?>
            </table>
            <?php if (!$job['DateClosed']): ?>
                <form method="POST">
                    <input type="hidden" name="activity_id" value="<?= htmlspecialchars($act['ActivityID']) ?>">
                    <select name="part_number" required>
                        <?php foreach ($parts as $p): ?>
                            <option value="<?= $p['PartNumber'] ?>">
                                <?= htmlspecialchars($p['PartName']) ?> (stock: <?= $p['CurrentStock'] ?>, <?= number_format($p['UnitPrice']) ?> VND)
                            </option>
                        <?php endforeach; ?>
                    </select>
                    Quantity: <input type="number" name="quantity_used" min="1" value="1" required>
                    <button type="submit" name="add_part" value="1">Record Part Usage</button>
                </form>
            <?php endif; ?>

            <strong>Mechanic Work Sessions</strong>
            <?php if (count($act['sessions']) === 0): ?>
                <p>No mechanic has logged work on this activity yet.</p>
            <?php else: ?>
                <table>
                    <tr><th>Mechanic</th><th>Start</th><th>End</th></tr>
                    <?php foreach ($act['sessions'] as $s): ?>
                        <tr>
                            <td><?= htmlspecialchars($s['FullName']) ?></td>
                            <td><?= htmlspecialchars($s['StartTime']) ?></td>
                            <td><?= htmlspecialchars($s['EndTime'] ?? 'In progress') ?></td>
                        </tr>
                    <?php endforeach; ?>
                </table>
            <?php endif; ?>
        </div>
    <?php endforeach; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
