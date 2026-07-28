<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Driver']);
require_once __DIR__ . '/../../config/db.php';

$driverId = $_SESSION['driver_id'];

$stmt = $pdo->prepare(
    'SELECT dc.DriverCertificationID, dct.DriverCertificationType, dc.IssueDate,
            dc.ExpiryDate, dc.Status, dc.StatusNotes
     FROM drivercertification dc
     JOIN drivercertificationtype dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
     WHERE dc.DriverID = :id
     ORDER BY dc.ExpiryDate DESC'
);
$stmt->execute(['id' => $driverId]);
$certs = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Certifications</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="driver_index.php">&larr; Back to dashboard</a>
    <h2>My Certifications</h2>

    <?php if (count($certs) === 0): ?>
        <p>No certifications on record.</p>
    <?php else: ?>
        <table>
            <tr>
                <th>Certification</th>
                <th>Issued</th>
                <th>Expires</th>
                <th>Status</th>
                <th>Notes</th>
            </tr>
            <?php foreach ($certs as $c): ?>
                <tr>
                    <td><?= htmlspecialchars($c['DriverCertificationType']) ?></td>
                    <td><?= htmlspecialchars($c['IssueDate']) ?></td>
                    <td><?= htmlspecialchars($c['ExpiryDate']) ?></td>
                    <td><?= htmlspecialchars($c['Status']) ?></td>
                    <td><?= htmlspecialchars($c['StatusNotes'] ?? '') ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
