<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Safety Staff']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$perPage = 10;

// --- Expiring within 30 days (Q4) ---
$expiringPage = currentPage('expiring_page');
$totalExpiring = (int)$pdo->query(
    "SELECT COUNT(*) FROM drivercertification
     WHERE Status IN ('Active', 'Reinstated') AND ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)"
)->fetchColumn();
$totalExpiringPages = max(1, (int)ceil($totalExpiring / $perPage));
$expiringPage = min($expiringPage, $totalExpiringPages);
$expiringOffset = ($expiringPage - 1) * $perPage;

$expiring = $pdo->query(
    "SELECT dr.DriverID, dr.FullName, dct.DriverCertificationType, dc.IssueDate, dc.ExpiryDate, dc.Status,
            DATEDIFF(dc.ExpiryDate, CURDATE()) AS DaysUntilExpiry
     FROM drivercertification dc
     JOIN driver dr ON dr.DriverID = dc.DriverID
     JOIN drivercertificationtype dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
     WHERE dc.Status IN ('Active', 'Reinstated')
       AND dc.ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
     ORDER BY dc.ExpiryDate ASC
     LIMIT $perPage OFFSET $expiringOffset"
)->fetchAll();

// --- Already expired (Q12) ---
$expiredPage = currentPage('expired_page');
$totalExpired = (int)$pdo->query(
    "SELECT COUNT(*) FROM drivercertification
     WHERE Status = 'Expired' OR (Status IN ('Active', 'Reinstated') AND ExpiryDate < CURDATE())"
)->fetchColumn();
$totalExpiredPages = max(1, (int)ceil($totalExpired / $perPage));
$expiredPage = min($expiredPage, $totalExpiredPages);
$expiredOffset = ($expiredPage - 1) * $perPage;

$expired = $pdo->query(
    "SELECT dr.DriverID, dr.FullName, dct.DriverCertificationType, dc.ExpiryDate, dc.Status
     FROM drivercertification dc
     JOIN driver dr ON dr.DriverID = dc.DriverID
     JOIN drivercertificationtype dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
     WHERE (dc.Status = 'Expired'
            OR (dc.Status IN ('Active', 'Reinstated') AND dc.ExpiryDate < CURDATE()))
     ORDER BY dc.ExpiryDate DESC
     LIMIT $perPage OFFSET $expiredOffset"
)->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Licence &amp; Certification Tracking</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="safety_staff_index.php">&larr; Back to dashboard</a>
    <h2>Licence &amp; Certification Tracking</h2>

    <h3>Expiring Within 30 Days</h3>
    <?php if (count($expiring) === 0): ?>
        <p>No certifications expiring soon.</p>
    <?php else: ?>
        <table>
            <tr><th>Driver</th><th>Certification</th><th>Issued</th><th>Expires</th><th>Days Left</th></tr>
            <?php foreach ($expiring as $e): ?>
                <tr>
                    <td><?= htmlspecialchars($e['FullName']) ?> (<?= htmlspecialchars($e['DriverID']) ?>)</td>
                    <td><?= htmlspecialchars($e['DriverCertificationType']) ?></td>
                    <td><?= htmlspecialchars($e['IssueDate']) ?></td>
                    <td><?= htmlspecialchars($e['ExpiryDate']) ?></td>
                    <td class="<?= $e['DaysUntilExpiry'] <= 7 ? 'score-critical' : 'score-warning' ?>"><?= htmlspecialchars($e['DaysUntilExpiry']) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($expiringPage, $totalExpiringPages, 'expiring_page') ?>
    <?php endif; ?>

    <h3>Already Expired</h3>
    <?php if (count($expired) === 0): ?>
        <p>No expired certifications on record.</p>
    <?php else: ?>
        <table>
            <tr><th>Driver</th><th>Certification</th><th>Expired On</th><th>Status</th></tr>
            <?php foreach ($expired as $e): ?>
                <tr>
                    <td><?= htmlspecialchars($e['FullName']) ?> (<?= htmlspecialchars($e['DriverID']) ?>)</td>
                    <td><?= htmlspecialchars($e['DriverCertificationType']) ?></td>
                    <td class="score-critical"><?= htmlspecialchars($e['ExpiryDate']) ?></td>
                    <td><?= htmlspecialchars($e['Status']) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($expiredPage, $totalExpiredPages, 'expired_page') ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
