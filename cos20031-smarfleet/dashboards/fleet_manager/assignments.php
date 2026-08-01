<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Fleet Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';
require_once __DIR__ . '/../../includes/pagination.php';

$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['create_assignment'])) {
            $stmt = $pdo->prepare(
                'INSERT INTO vehicleassignment (VIN, DriverID, DepotID, IssueDate, AssignmentStatus)
                 VALUES (:vin, :driverId, :depotId, NOW(), \'Pending\')'
            );
            $stmt->execute(['vin' => $_POST['vin'], 'driverId' => $_POST['driver_id'], 'depotId' => $_POST['depot_id']]);
            $message = 'Assignment booked as Pending.';
        } elseif (isset($_POST['start_assignment'])) {
            $stmt = $pdo->prepare(
                "UPDATE vehicleassignment SET AssignmentStatus = 'In Operation', StartDate = NOW()
                 WHERE AssignmentID = :id AND AssignmentStatus = 'Pending'"
            );
            $stmt->execute(['id' => $_POST['assignment_id']]);
            $message = 'Assignment started.';
        } elseif (isset($_POST['complete_assignment'])) {
            $stmt = $pdo->prepare(
                "UPDATE vehicleassignment SET AssignmentStatus = 'Completed', EndDate = NOW()
                 WHERE AssignmentID = :id AND AssignmentStatus = 'In Operation'"
            );
            $stmt->execute(['id' => $_POST['assignment_id']]);
            $message = 'Assignment completed.';
        } elseif (isset($_POST['cancel_assignment'])) {
            $stmt = $pdo->prepare(
                "UPDATE vehicleassignment SET AssignmentStatus = 'Cancelled', EndDate = NOW()
                 WHERE AssignmentID = :id AND AssignmentStatus IN ('Pending', 'In Operation')"
            );
            $stmt->execute(['id' => $_POST['assignment_id']]);
            $message = 'Assignment cancelled.';
        }
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$statusFilter = $_GET['status'] ?? '';
$driverFilter = $_GET['driver_id'] ?? '';

$depots = $pdo->query('SELECT DepotID, DepotName FROM depot ORDER BY DepotName')->fetchAll();

$perPage = 10;
$page = currentPage('page');

$whereClause = 'WHERE (:status = \'\' OR va.AssignmentStatus = :status)
       AND (:driverId = \'\' OR va.DriverID = :driverId)';
$filterParams = ['status' => $statusFilter, 'driverId' => $driverFilter];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM vehicleassignment va $whereClause");
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT va.AssignmentID, va.VIN, v.RegistrationNumber, va.DriverID, dr.FullName, d.DepotName,
            va.IssueDate, va.StartDate, va.EndDate, va.AssignmentStatus,
            dr.EmploymentStatus, dr.DrivingEligibility, vs.VehicleStatus,
            EXISTS (
                SELECT 1 FROM vehiclecertificationrequirement vcr
                WHERE vcr.VehicleCategoryID = v.CategoryID
                  AND NOT EXISTS (
                      SELECT 1 FROM drivercertification dc
                      WHERE dc.DriverID = va.DriverID
                        AND dc.DriverCertificationTypeID = vcr.DriverCertificationTypeID
                        AND dc.Status IN ('Active', 'Reinstated')
                        AND dc.ExpiryDate > CURDATE()
                  )
            ) AS MissingCertification
     FROM vehicleassignment va
     JOIN vehicle v ON v.VIN = va.VIN
     JOIN vehiclestatus vs ON vs.VehicleStatusID = v.OperationalStatus
     JOIN driver dr ON dr.DriverID = va.DriverID
     JOIN depot d ON d.DepotID = va.DepotID
     $whereClause
     ORDER BY va.IssueDate DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$assignments = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Vehicle Assignments</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="fleet_manager_index.php">&larr; Back to dashboard</a>
    <h2>Vehicle Assignments</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <h3>Book New Assignment</h3>
    <form method="POST">
        VIN: <input type="text" name="vin" maxlength="17" placeholder="17-character VIN" required>
        Driver ID: <input type="text" name="driver_id" placeholder="e.g. D-0001" required>
        Depot:
        <select name="depot_id" required>
            <?php foreach ($depots as $d): ?>
                <option value="<?= $d['DepotID'] ?>"><?= htmlspecialchars($d['DepotName']) ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit" name="create_assignment" value="1">Book (Pending)</button>
    </form>
    <p><em>Vehicle and driver eligibility (certifications, employment status, vehicle availability) are checked automatically when an assignment is started.</em></p>

    <h3>Assignments</h3>
    <form method="GET">
        <select name="status">
            <option value="">All Statuses</option>
            <?php foreach (['Pending', 'In Operation', 'Completed', 'Cancelled'] as $s): ?>
                <option value="<?= $s ?>" <?= $statusFilter === $s ? 'selected' : '' ?>><?= $s ?></option>
            <?php endforeach; ?>
        </select>
        <input type="text" name="driver_id" placeholder="Driver ID" value="<?= htmlspecialchars($driverFilter) ?>">
        <button type="submit">Filter</button>
        <a href="assignments.php">Clear</a>
    </form>

    <p><?= htmlspecialchars($totalRows) ?> assignment(s)</p>

    <table>
        <tr><th>ID</th><th>Vehicle</th><th>Driver</th><th>Depot</th><th>Issued</th><th>Started</th><th>Ended</th><th>Status</th><th>Actions</th></tr>
        <?php foreach ($assignments as $a):
            $driverBlocked = $a['EmploymentStatus'] !== 'Active' || $a['DrivingEligibility'] !== 'Eligible';
            $vehicleBlocked = $a['VehicleStatus'] !== 'Available';
        ?>
            <tr>
                <td><?= htmlspecialchars($a['AssignmentID']) ?></td>
                <td>
                    <?= htmlspecialchars($a['RegistrationNumber']) ?>
                    <?php if ($a['AssignmentStatus'] === 'Pending' && $vehicleBlocked): ?>
                        <br><span class="score-critical">&#9888; Vehicle is <?= htmlspecialchars($a['VehicleStatus']) ?>, not Available</span>
                    <?php endif; ?>
                </td>
                <td>
                    <?= htmlspecialchars($a['FullName']) ?> (<?= htmlspecialchars($a['DriverID']) ?>)
                    <?php if ($a['AssignmentStatus'] === 'Pending' && $driverBlocked): ?>
                        <br><span class="score-critical">&#9888; <?= htmlspecialchars($a['EmploymentStatus']) ?>, <?= htmlspecialchars($a['DrivingEligibility']) ?></span>
                    <?php endif; ?>
                    <?php if ($a['AssignmentStatus'] === 'Pending' && $a['MissingCertification']): ?>
                        <br><span class="score-critical">&#9888; Missing a required certification for this vehicle category</span>
                    <?php endif; ?>
                </td>
                <td><?= htmlspecialchars($a['DepotName']) ?></td>
                <td><?= htmlspecialchars($a['IssueDate']) ?></td>
                <td><?= htmlspecialchars($a['StartDate'] ?? '') ?></td>
                <td><?= htmlspecialchars($a['EndDate'] ?? '') ?></td>
                <td><?= htmlspecialchars($a['AssignmentStatus']) ?></td>
                <td>
                    <?php if ($a['AssignmentStatus'] === 'Pending'): ?>
                        <form method="POST" style="display:inline;">
                            <input type="hidden" name="assignment_id" value="<?= $a['AssignmentID'] ?>">
                            <button type="submit" name="start_assignment" value="1">Start</button>
                        </form>
                        <form method="POST" style="display:inline;">
                            <input type="hidden" name="assignment_id" value="<?= $a['AssignmentID'] ?>">
                            <button type="submit" name="cancel_assignment" value="1">Cancel</button>
                        </form>
                    <?php elseif ($a['AssignmentStatus'] === 'In Operation'): ?>
                        <form method="POST" style="display:inline;">
                            <input type="hidden" name="assignment_id" value="<?= $a['AssignmentID'] ?>">
                            <button type="submit" name="complete_assignment" value="1">Complete</button>
                        </form>
                        <form method="POST" style="display:inline;">
                            <input type="hidden" name="assignment_id" value="<?= $a['AssignmentID'] ?>">
                            <button type="submit" name="cancel_assignment" value="1">Cancel</button>
                        </form>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
