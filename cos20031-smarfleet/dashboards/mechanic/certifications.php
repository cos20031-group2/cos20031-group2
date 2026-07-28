<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Mechanic']);
require_once __DIR__ . '/../../config/db.php';

$mechanicId = $_SESSION['mechanic_id'];

$stmt = $pdo->prepare(
    'SELECT mc.MechanicCertificationID, mct.MechanicCertificationType, mc.IssueDate,
            mc.ExpiryDate, mc.Status, mc.StatusNotes
     FROM mechaniccertification mc
     JOIN mechaniccertificationtype mct ON mct.MechanicCertificationTypeID = mc.MechanicCertificationTypeID
     WHERE mc.MechanicID = :id
     ORDER BY mc.ExpiryDate DESC'
);
$stmt->execute(['id' => $mechanicId]);
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

    <a class="back-link" href="mechanic_index.php">&larr; Back to dashboard</a>
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
                    <td><?= htmlspecialchars($c['MechanicCertificationType']) ?></td>
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
