<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Fleet Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';

$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['issue_cert'])) {
            $stmt = $pdo->prepare(
                'INSERT INTO drivercertification (DriverID, DriverCertificationTypeID, IssueDate, ExpiryDate, Status)
                 VALUES (:driverId, :typeId, :issueDate, :expiryDate, \'Active\')'
            );
            $stmt->execute([
                'driverId' => $_POST['driver_id'], 'typeId' => $_POST['cert_type_id'],
                'issueDate' => $_POST['issue_date'], 'expiryDate' => $_POST['expiry_date'],
            ]);
            $message = 'Certification issued.';
        } elseif (isset($_POST['update_status'])) {
            $newStatus = $_POST['new_status'];
            $revocationDate = null;

            if ($newStatus === 'Revoked') {
                $revocationDate = $_POST['revocation_date'] ?: date('Y-m-d');
            } elseif ($newStatus === 'Reinstated') {
                // Must already have a revocation date on file -- keep the existing one.
                $s = $pdo->prepare('SELECT RevocationDate FROM drivercertification WHERE DriverCertificationID = :id');
                $s->execute(['id' => $_POST['cert_id']]);
                $revocationDate = $s->fetchColumn();
            } elseif ($newStatus === 'Voided') {
                $revocationDate = $_POST['revocation_date'] ?: null;
            }
            // 'Active' and 'Expired' -> RevocationDate stays NULL unless Voided path set it above.

            $stmt = $pdo->prepare(
                'UPDATE drivercertification
                 SET Status = :status, RevocationDate = :revocationDate, StatusNotes = :notes
                 WHERE DriverCertificationID = :id'
            );
            $stmt->execute([
                'status' => $newStatus, 'revocationDate' => $revocationDate,
                'notes' => $_POST['status_notes'], 'id' => $_POST['cert_id'],
            ]);
            $message = 'Certification status updated.';
        }
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$driverId = $_GET['driver_id'] ?? '';
$certTypes = $pdo->query('SELECT DriverCertificationTypeID, DriverCertificationType FROM drivercertificationtype ORDER BY DriverCertificationType')->fetchAll();

$driver = null;
$certs = [];
if ($driverId !== '') {
    $s = $pdo->prepare('SELECT DriverID, FullName FROM driver WHERE DriverID = :id');
    $s->execute(['id' => $driverId]);
    $driver = $s->fetch();

    if ($driver) {
        $stmt = $pdo->prepare(
            'SELECT dc.DriverCertificationID, dct.DriverCertificationType, dc.IssueDate, dc.ExpiryDate,
                    dc.RevocationDate, dc.Status, dc.StatusNotes
             FROM drivercertification dc
             JOIN drivercertificationtype dct ON dct.DriverCertificationTypeID = dc.DriverCertificationTypeID
             WHERE dc.DriverID = :id
             ORDER BY dc.ExpiryDate DESC'
        );
        $stmt->execute(['id' => $driverId]);
        $certs = $stmt->fetchAll();
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Driver Certifications</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="fleet_manager_index.php">&larr; Back to dashboard</a>
    <h2>Driver Certifications</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <form method="GET">
        <input type="text" name="driver_id" placeholder="Driver ID, e.g. D-0001" value="<?= htmlspecialchars($driverId) ?>" required>
        <button type="submit">Look Up</button>
    </form>

    <?php if ($driverId !== '' && !$driver): ?>
        <p>No driver found with that ID.</p>
    <?php elseif ($driver): ?>
        <h3><?= htmlspecialchars($driver['FullName']) ?> (<?= htmlspecialchars($driver['DriverID']) ?>)</h3>

        <h4>Issue New Certification</h4>
        <form method="POST">
            <input type="hidden" name="driver_id" value="<?= htmlspecialchars($driverId) ?>">
            <select name="cert_type_id" required>
                <?php foreach ($certTypes as $ct): ?>
                    <option value="<?= $ct['DriverCertificationTypeID'] ?>"><?= htmlspecialchars($ct['DriverCertificationType']) ?></option>
                <?php endforeach; ?>
            </select>
            Issue Date: <input type="date" name="issue_date" required>
            Expiry Date: <input type="date" name="expiry_date" required>
            <button type="submit" name="issue_cert" value="1">Issue</button>
        </form>

        <h4>Existing Certifications</h4>
        <?php if (count($certs) === 0): ?>
            <p>No certifications on record for this driver.</p>
        <?php else: ?>
            <table>
                <tr><th>Certification</th><th>Issued</th><th>Expires</th><th>Revoked</th><th>Status</th><th>Notes</th><th>Change Status</th></tr>
                <?php foreach ($certs as $c): ?>
                    <tr>
                        <td><?= htmlspecialchars($c['DriverCertificationType']) ?></td>
                        <td><?= htmlspecialchars($c['IssueDate']) ?></td>
                        <td><?= htmlspecialchars($c['ExpiryDate']) ?></td>
                        <td><?= htmlspecialchars($c['RevocationDate'] ?? '') ?></td>
                        <td><?= htmlspecialchars($c['Status']) ?></td>
                        <td><?= htmlspecialchars($c['StatusNotes'] ?? '') ?></td>
                        <td>
                            <details>
                                <summary>Update</summary>
                                <form method="POST">
                                    <input type="hidden" name="cert_id" value="<?= htmlspecialchars($c['DriverCertificationID']) ?>">
                                    <select name="new_status">
                                        <option value="Active">Active</option>
                                        <option value="Revoked">Revoked</option>
                                        <option value="Expired">Expired</option>
                                        <option value="Voided">Voided</option>
                                        <option value="Reinstated">Reinstated</option>
                                    </select>
                                    Revocation Date (if Revoked/Voided): <input type="date" name="revocation_date">
                                    Notes: <input type="text" name="status_notes" value="<?= htmlspecialchars($c['StatusNotes'] ?? '') ?>">
                                    <button type="submit" name="update_status" value="1">Save</button>
                                </form>
                            </details>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </table>
        <?php endif; ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
