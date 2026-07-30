<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Safety Staff']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$perPage = 10;
$page = currentPage('page');

$baseQuery = "FROM vehicleassignment va
     JOIN vehicle v ON v.VIN = va.VIN
     JOIN vehiclecertificationrequirement vcr ON vcr.VehicleCategoryID = v.CategoryID
     JOIN drivercertification dc
         ON dc.DriverID = va.DriverID
        AND dc.DriverCertificationTypeID = vcr.DriverCertificationTypeID
     JOIN drivercertificationtype dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
     JOIN driver dr ON dr.DriverID = va.DriverID
     WHERE va.StartDate IS NOT NULL
       AND dc.Status = 'Voided'
       AND dc.IssueDate <= va.StartDate
       AND dc.ExpiryDate >= va.StartDate";

$totalRows = (int)$pdo->query("SELECT COUNT(*) $baseQuery")->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$results = $pdo->query(
    "SELECT va.AssignmentID, va.VIN, va.DriverID, dr.FullName, va.StartDate, va.AssignmentStatus,
            dct.DriverCertificationType, dc.DriverCertificationID, dc.IssueDate, dc.ExpiryDate, dc.StatusNotes
     $baseQuery
     ORDER BY va.StartDate
     LIMIT $perPage OFFSET $offset"
)->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Certification Audit</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="safety_staff_index.php">&larr; Back to dashboard</a>
    <h2>Certification Audit</h2>
    <p>Vehicle assignments that relied on a driver certification later marked Voided --
       these drivers were operating outside their authorised vehicle category at the time.</p>

    <?php if (count($results) === 0): ?>
        <p>No affected assignments found.</p>
    <?php else: ?>
        <table>
            <tr>
                <th>Assignment</th><th>Vehicle</th><th>Driver</th><th>Start Date</th>
                <th>Assignment Status</th><th>Certification</th><th>Voided Notes</th>
            </tr>
            <?php foreach ($results as $r): ?>
                <tr>
                    <td><?= htmlspecialchars($r['AssignmentID']) ?></td>
                    <td><?= htmlspecialchars($r['VIN']) ?></td>
                    <td><?= htmlspecialchars($r['FullName']) ?> (<?= htmlspecialchars($r['DriverID']) ?>)</td>
                    <td><?= htmlspecialchars($r['StartDate']) ?></td>
                    <td><?= htmlspecialchars($r['AssignmentStatus']) ?></td>
                    <td><?= htmlspecialchars($r['DriverCertificationType']) ?></td>
                    <td class="score-critical"><?= htmlspecialchars($r['StatusNotes'] ?? '') ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($page, $totalPages, 'page') ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
