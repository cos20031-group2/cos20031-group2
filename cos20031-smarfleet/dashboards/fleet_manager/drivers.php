<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Fleet Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';
require_once __DIR__ . '/../../includes/pagination.php';

$message = '';
$error = '';

function nextDriverId(PDO $pdo): string
{
    $max = $pdo->query("SELECT MAX(DriverID) FROM driver WHERE DriverID LIKE 'D-%'")->fetchColumn();
    $nextNum = $max ? ((int)substr($max, 2)) + 1 : 1;
    return 'D-' . str_pad((string)$nextNum, 4, '0', STR_PAD_LEFT);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['add_driver'])) {
            $newId = nextDriverId($pdo);
            $stmt = $pdo->prepare(
                'INSERT INTO driver (DriverID, FullName, ContactInfo, CurrentDepotID, EmploymentStatus, EmergencyContactDetails)
                 VALUES (:id, :name, :contact, :depot, :status, :emergency)'
            );
            $stmt->execute([
                'id' => $newId, 'name' => $_POST['full_name'], 'contact' => $_POST['contact_info'],
                'depot' => $_POST['depot_id'], 'status' => $_POST['employment_status'], 'emergency' => $_POST['emergency_contact'],
            ]);
            $message = "Driver added ($newId).";
        } elseif (isset($_POST['update_driver'])) {
            $stmt = $pdo->prepare(
                'UPDATE driver
                 SET FullName = :name, ContactInfo = :contact, CurrentDepotID = :depot,
                     EmploymentStatus = :status, EmergencyContactDetails = :emergency
                 WHERE DriverID = :id'
            );
            $stmt->execute([
                'name' => $_POST['full_name'], 'contact' => $_POST['contact_info'], 'depot' => $_POST['depot_id'],
                'status' => $_POST['employment_status'], 'emergency' => $_POST['emergency_contact'], 'id' => $_POST['driver_id'],
            ]);
            $message = 'Driver updated.';
        }
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$depotId = $_GET['depot_id'] ?? '';
$employmentStatus = $_GET['employment_status'] ?? '';
$editId = $_GET['edit'] ?? '';

$depots = $pdo->query('SELECT DepotID, DepotName FROM depot ORDER BY DepotName')->fetchAll();

$perPage = 10;
$page = currentPage('page');

$whereClause = 'WHERE (:depotId = \'\' OR dr.CurrentDepotID = :depotId)
       AND (:employmentStatus = \'\' OR dr.EmploymentStatus = :employmentStatus)';
$filterParams = ['depotId' => $depotId, 'employmentStatus' => $employmentStatus];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM driver dr $whereClause");
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT dr.DriverID, dr.FullName, dr.ContactInfo, dr.CurrentDepotID, d.DepotName,
            dr.EmploymentStatus, dr.EmergencyContactDetails, dr.DrivingEligibility
     FROM driver dr
     LEFT JOIN depot d ON d.DepotID = dr.CurrentDepotID
     $whereClause
     ORDER BY dr.FullName
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$drivers = $stmt->fetchAll();

$editDriver = null;
if ($editId !== '') {
    $s2 = $pdo->prepare(
        'SELECT dr.*, d.DepotName FROM driver dr LEFT JOIN depot d ON d.DepotID = dr.CurrentDepotID WHERE dr.DriverID = :id'
    );
    $s2->execute(['id' => $editId]);
    $editDriver = $s2->fetch();
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Drivers</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="fleet_manager_index.php">&larr; Back to dashboard</a>
    <h2>Drivers</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <h3><?= $editDriver ? 'Edit Driver' : 'Add Driver' ?></h3>
    <form method="POST">
        <?php if ($editDriver): ?>
            <input type="hidden" name="driver_id" value="<?= htmlspecialchars($editDriver['DriverID']) ?>">
            Driver ID: <?= htmlspecialchars($editDriver['DriverID']) ?> (cannot be changed)<br>
        <?php endif; ?>
        Full Name: <input type="text" name="full_name" value="<?= htmlspecialchars($editDriver['FullName'] ?? '') ?>" required><br>
        Contact Info: <input type="text" name="contact_info" value="<?= htmlspecialchars($editDriver['ContactInfo'] ?? '') ?>" required><br>
        Emergency Contact: <input type="text" name="emergency_contact" value="<?= htmlspecialchars($editDriver['EmergencyContactDetails'] ?? '') ?>" required><br>
        Depot:
        <select name="depot_id" required>
            <?php foreach ($depots as $d): ?>
                <option value="<?= $d['DepotID'] ?>" <?= ($editDriver['CurrentDepotID'] ?? '') == $d['DepotID'] ? 'selected' : '' ?>>
                    <?= htmlspecialchars($d['DepotName']) ?>
                </option>
            <?php endforeach; ?>
        </select><br>
        Employment Status:
        <select name="employment_status" required>
            <?php foreach (['Active', 'On Leave', 'Terminated'] as $s): ?>
                <option value="<?= $s ?>" <?= ($editDriver['EmploymentStatus'] ?? '') === $s ? 'selected' : '' ?>><?= $s ?></option>
            <?php endforeach; ?>
        </select><br>
        <?php if ($editDriver): ?>
            Driving Eligibility: <?= htmlspecialchars($editDriver['DrivingEligibility']) ?>
            <em>(system-managed -- changes automatically based on safety score, coaching, and certifications)</em><br>
        <?php endif; ?>
        <br>
        <?php if ($editDriver): ?>
            <button type="submit" name="update_driver" value="1">Save Changes</button>
            <a href="drivers.php">Cancel</a>
        <?php else: ?>
            <button type="submit" name="add_driver" value="1">Add Driver</button>
        <?php endif; ?>
    </form>

    <h3>All Drivers</h3>
    <form method="GET">
        <select name="depot_id">
            <option value="">All Depots</option>
            <?php foreach ($depots as $d): ?>
                <option value="<?= $d['DepotID'] ?>" <?= $depotId == $d['DepotID'] ? 'selected' : '' ?>><?= htmlspecialchars($d['DepotName']) ?></option>
            <?php endforeach; ?>
        </select>
        <select name="employment_status">
            <option value="">All Employment Statuses</option>
            <?php foreach (['Active', 'On Leave', 'Terminated'] as $s): ?>
                <option value="<?= $s ?>" <?= $employmentStatus === $s ? 'selected' : '' ?>><?= $s ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="drivers.php">Clear</a>
    </form>

    <p><?= htmlspecialchars($totalRows) ?> driver(s)</p>

    <table>
        <tr><th>Driver ID</th><th>Name</th><th>Contact</th><th>Depot</th><th>Employment</th><th>Eligibility</th><th></th></tr>
        <?php foreach ($drivers as $d): ?>
            <tr>
                <td><?= htmlspecialchars($d['DriverID']) ?></td>
                <td><?= htmlspecialchars($d['FullName']) ?></td>
                <td><?= htmlspecialchars($d['ContactInfo']) ?></td>
                <td><?= htmlspecialchars($d['DepotName'] ?? '') ?></td>
                <td><?= htmlspecialchars($d['EmploymentStatus']) ?></td>
                <td class="<?= $d['DrivingEligibility'] === 'Suspended' ? 'score-critical' : 'score-good' ?>"><?= htmlspecialchars($d['DrivingEligibility']) ?></td>
                <td><a href="?<?= http_build_query(array_merge($_GET, ['edit' => $d['DriverID']])) ?>">Edit</a></td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
