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
        if (isset($_POST['add_vehicle'])) {
            $stmt = $pdo->prepare(
                'INSERT INTO vehicle (VIN, RegistrationNumber, CategoryID, Model, Manufacturer, YearOfManufacture, Odometer, DepotID, OperationalStatus)
                 VALUES (:vin, :reg, :category, :model, :manufacturer, :year, :odometer, :depot, :status)'
            );
            $stmt->execute([
                'vin' => $_POST['vin'], 'reg' => $_POST['registration'], 'category' => $_POST['category_id'],
                'model' => $_POST['model'], 'manufacturer' => $_POST['manufacturer'], 'year' => $_POST['year'],
                'odometer' => $_POST['odometer'], 'depot' => $_POST['depot_id'], 'status' => $_POST['status_id'],
            ]);
            $message = 'Vehicle added.';
        } elseif (isset($_POST['update_vehicle'])) {
            $stmt = $pdo->prepare(
                'UPDATE vehicle
                 SET RegistrationNumber = :reg, CategoryID = :category, Model = :model, Manufacturer = :manufacturer,
                     YearOfManufacture = :year, Odometer = :odometer, DepotID = :depot, OperationalStatus = :status
                 WHERE VIN = :vin'
            );
            $stmt->execute([
                'reg' => $_POST['registration'], 'category' => $_POST['category_id'], 'model' => $_POST['model'],
                'manufacturer' => $_POST['manufacturer'], 'year' => $_POST['year'], 'odometer' => $_POST['odometer'],
                'depot' => $_POST['depot_id'], 'status' => $_POST['status_id'], 'vin' => $_POST['vin'],
            ]);
            $message = 'Vehicle updated.';
        } elseif (isset($_POST['delete_vehicle'])) {
            $stmt = $pdo->prepare('DELETE FROM vehicle WHERE VIN = :vin');
            $stmt->execute(['vin' => $_POST['vin']]);
            $message = 'Vehicle deleted.';
        }
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$depotId = $_GET['depot_id'] ?? '';
$categoryId = $_GET['category_id'] ?? '';
$statusId = $_GET['status_id'] ?? '';
$editVin = $_GET['edit'] ?? '';

$depots = $pdo->query('SELECT DepotID, DepotName FROM depot ORDER BY DepotName')->fetchAll();
$categories = $pdo->query('SELECT VehicleCategoryID, VehicleCategory FROM vehiclecategory ORDER BY VehicleCategory')->fetchAll();
$statuses = $pdo->query('SELECT VehicleStatusID, VehicleStatus FROM vehiclestatus ORDER BY VehicleStatus')->fetchAll();

$perPage = 10;
$page = currentPage('page');

$whereClause = 'WHERE (:depotId = \'\' OR v.DepotID = :depotId)
       AND (:categoryId = \'\' OR v.CategoryID = :categoryId)
       AND (:statusId = \'\' OR v.OperationalStatus = :statusId)';
$filterParams = ['depotId' => $depotId, 'categoryId' => $categoryId, 'statusId' => $statusId];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM vehicle v $whereClause");
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT v.VIN, v.RegistrationNumber, v.Model, v.Manufacturer, v.YearOfManufacture, v.Odometer,
            d.DepotName, d.DepotID, vc.VehicleCategory, vc.VehicleCategoryID, vs.VehicleStatus, v.OperationalStatus
     FROM vehicle v
     JOIN depot d ON d.DepotID = v.DepotID
     JOIN vehiclecategory vc ON vc.VehicleCategoryID = v.CategoryID
     JOIN vehiclestatus vs ON vs.VehicleStatusID = v.OperationalStatus
     $whereClause
     ORDER BY v.RegistrationNumber
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$vehicles = $stmt->fetchAll();

$editVehicle = null;
if ($editVin !== '') {
    $s2 = $pdo->prepare('SELECT * FROM vehicle WHERE VIN = :vin');
    $s2->execute(['vin' => $editVin]);
    $editVehicle = $s2->fetch();
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Vehicles</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="fleet_manager_index.php">&larr; Back to dashboard</a>
    <h2>Vehicles</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <h3><?= $editVehicle ? 'Edit Vehicle' : 'Add Vehicle' ?></h3>
    <form method="POST">
        <?php if ($editVehicle): ?>
            <input type="hidden" name="vin" value="<?= htmlspecialchars($editVehicle['VIN']) ?>">
            VIN: <?= htmlspecialchars($editVehicle['VIN']) ?> (cannot be changed)<br>
        <?php else: ?>
            VIN: <input type="text" name="vin" maxlength="17" placeholder="17-character VIN" required><br>
        <?php endif; ?>
        Registration: <input type="text" name="registration" placeholder="e.g. 84V-244.44"
            value="<?= htmlspecialchars($editVehicle['RegistrationNumber'] ?? '') ?>" required><br>
        Model: <input type="text" name="model" value="<?= htmlspecialchars($editVehicle['Model'] ?? '') ?>" required><br>
        Manufacturer: <input type="text" name="manufacturer" value="<?= htmlspecialchars($editVehicle['Manufacturer'] ?? '') ?>" required><br>
        Year: <input type="number" name="year" min="1980" value="<?= htmlspecialchars($editVehicle['YearOfManufacture'] ?? '') ?>" required><br>
        Odometer: <input type="number" name="odometer" min="0" value="<?= htmlspecialchars($editVehicle['Odometer'] ?? '0') ?>" required><br>
        Category:
        <select name="category_id" required>
            <?php foreach ($categories as $c): ?>
                <option value="<?= $c['VehicleCategoryID'] ?>" <?= ($editVehicle['CategoryID'] ?? '') == $c['VehicleCategoryID'] ? 'selected' : '' ?>>
                    <?= htmlspecialchars($c['VehicleCategory']) ?>
                </option>
            <?php endforeach; ?>
        </select><br>
        Depot:
        <select name="depot_id" required>
            <?php foreach ($depots as $d): ?>
                <option value="<?= $d['DepotID'] ?>" <?= ($editVehicle['DepotID'] ?? '') == $d['DepotID'] ? 'selected' : '' ?>>
                    <?= htmlspecialchars($d['DepotName']) ?>
                </option>
            <?php endforeach; ?>
        </select><br>
        Status:
        <select name="status_id" required>
            <?php foreach ($statuses as $s): ?>
                <option value="<?= $s['VehicleStatusID'] ?>" <?= ($editVehicle['OperationalStatus'] ?? '') == $s['VehicleStatusID'] ? 'selected' : '' ?>>
                    <?= htmlspecialchars($s['VehicleStatus']) ?>
                </option>
            <?php endforeach; ?>
        </select><br><br>
        <?php if ($editVehicle): ?>
            <button type="submit" name="update_vehicle" value="1">Save Changes</button>
            <a href="vehicles.php">Cancel</a>
        <?php else: ?>
            <button type="submit" name="add_vehicle" value="1">Add Vehicle</button>
        <?php endif; ?>
    </form>

    <h3>Fleet</h3>
    <form method="GET">
        <select name="depot_id">
            <option value="">All Depots</option>
            <?php foreach ($depots as $d): ?>
                <option value="<?= $d['DepotID'] ?>" <?= $depotId == $d['DepotID'] ? 'selected' : '' ?>><?= htmlspecialchars($d['DepotName']) ?></option>
            <?php endforeach; ?>
        </select>
        <select name="category_id">
            <option value="">All Categories</option>
            <?php foreach ($categories as $c): ?>
                <option value="<?= $c['VehicleCategoryID'] ?>" <?= $categoryId == $c['VehicleCategoryID'] ? 'selected' : '' ?>><?= htmlspecialchars($c['VehicleCategory']) ?></option>
            <?php endforeach; ?>
        </select>
        <select name="status_id">
            <option value="">All Statuses</option>
            <?php foreach ($statuses as $s): ?>
                <option value="<?= $s['VehicleStatusID'] ?>" <?= $statusId == $s['VehicleStatusID'] ? 'selected' : '' ?>><?= htmlspecialchars($s['VehicleStatus']) ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="vehicles.php">Clear</a>
    </form>

    <p><?= htmlspecialchars($totalRows) ?> vehicle(s)</p>

    <table>
        <tr><th>VIN</th><th>Registration</th><th>Model</th><th>Manufacturer</th><th>Year</th><th>Odometer</th><th>Depot</th><th>Category</th><th>Status</th><th></th></tr>
        <?php foreach ($vehicles as $v): ?>
            <tr>
                <td><?= htmlspecialchars($v['VIN']) ?></td>
                <td><?= htmlspecialchars($v['RegistrationNumber']) ?></td>
                <td><?= htmlspecialchars($v['Model']) ?></td>
                <td><?= htmlspecialchars($v['Manufacturer']) ?></td>
                <td><?= htmlspecialchars($v['YearOfManufacture']) ?></td>
                <td><?= htmlspecialchars($v['Odometer']) ?></td>
                <td><?= htmlspecialchars($v['DepotName']) ?></td>
                <td><?= htmlspecialchars($v['VehicleCategory']) ?></td>
                <td><?= htmlspecialchars($v['VehicleStatus']) ?></td>
                <td>
                    <a href="?<?= http_build_query(array_merge($_GET, ['edit' => $v['VIN']])) ?>">Edit</a>
                    <form method="POST" style="display:inline;" onsubmit="return confirm('Delete this vehicle?');">
                        <input type="hidden" name="vin" value="<?= htmlspecialchars($v['VIN']) ?>">
                        <button type="submit" name="delete_vehicle" value="1">Delete</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
