<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Fleet Manager']);
require_once __DIR__ . '/../../config/db.php';

// Reference matrix: which certifications are required to drive each vehicle category --
// same information as the Vehicle Certification Matrix in the project brief.
$categories = $pdo->query('SELECT VehicleCategoryID, VehicleCategory FROM vehiclecategory ORDER BY VehicleCategory')->fetchAll();
$certTypes = $pdo->query('SELECT DriverCertificationTypeID, DriverCertificationType FROM drivercertificationtype ORDER BY DriverCertificationType')->fetchAll();

$requirements = $pdo->query('SELECT VehicleCategoryID, DriverCertificationTypeID FROM vehiclecertificationrequirement')->fetchAll();
$requiredSet = [];
foreach ($requirements as $r) {
    $requiredSet[$r['VehicleCategoryID']][$r['DriverCertificationTypeID']] = true;
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Vehicle Certification Requirements</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="fleet_manager_index.php">&larr; Back to dashboard</a>
    <h2>Vehicle Certification Requirements</h2>
    <p>To drive a given vehicle category, a driver must hold ALL certifications marked below.</p>

    <table>
        <tr>
            <th>Vehicle Category</th>
            <?php foreach ($certTypes as $ct): ?>
                <th><?= htmlspecialchars($ct['DriverCertificationType']) ?></th>
            <?php endforeach; ?>
        </tr>
        <?php foreach ($categories as $cat): ?>
            <tr>
                <td><?= htmlspecialchars($cat['VehicleCategory']) ?></td>
                <?php foreach ($certTypes as $ct): ?>
                    <td style="text-align:center;">
                        <?= isset($requiredSet[$cat['VehicleCategoryID']][$ct['DriverCertificationTypeID']]) ? '&#10003;' : '' ?>
                    </td>
                <?php endforeach; ?>
            </tr>
        <?php endforeach; ?>
    </table>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
