<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';
require_once __DIR__ . '/../../includes/pagination.php';

$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['issue_cert'])) {
            $stmt = $pdo->prepare(
                'INSERT INTO mechaniccertification (MechanicID, MechanicCertificationTypeID, IssueDate, ExpiryDate, Status)
                 VALUES (:mechanicId, :typeId, :issueDate, :expiryDate, \'Active\')'
            );
            $stmt->execute([
                'mechanicId' => $_POST['mechanic_id'], 'typeId' => $_POST['cert_type_id'],
                'issueDate' => $_POST['issue_date'], 'expiryDate' => $_POST['expiry_date'],
            ]);
            $message = 'Certification issued.';
        } elseif (isset($_POST['update_status'])) {
            $newStatus = $_POST['new_status'];
            $revocationDate = null;

            if ($newStatus === 'Revoked') {
                $revocationDate = $_POST['revocation_date'] ?: date('Y-m-d');
            } elseif ($newStatus === 'Reinstated') {
                $s = $pdo->prepare('SELECT RevocationDate FROM mechaniccertification WHERE MechanicCertificationID = :id');
                $s->execute(['id' => $_POST['cert_id']]);
                $revocationDate = $s->fetchColumn();
            } elseif ($newStatus === 'Voided') {
                $revocationDate = $_POST['revocation_date'] ?: null;
            }

            $stmt = $pdo->prepare(
                'UPDATE mechaniccertification
                 SET Status = :status, RevocationDate = :revocationDate, StatusNotes = :notes
                 WHERE MechanicCertificationID = :id'
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

$mechanicId = $_GET['mechanic_id'] ?? '';
$certTypeFilter = $_GET['cert_type_filter'] ?? '';
$workshopFilter = $_GET['workshop_filter'] ?? '';
$workshops = $pdo->query('SELECT WorkshopID, Name FROM workshop ORDER BY Name')->fetchAll();
$certTypes = $pdo->query('SELECT MechanicCertificationTypeID, MechanicCertificationType FROM mechaniccertificationtype ORDER BY MechanicCertificationType')->fetchAll();

$mechanic = null;
$certs = [];
if ($mechanicId !== '') {
    $s = $pdo->prepare('SELECT MechanicID, FullName FROM mechanic WHERE MechanicID = :id');
    $s->execute(['id' => $mechanicId]);
    $mechanic = $s->fetch();

    if ($mechanic) {
        $stmt = $pdo->prepare(
            'SELECT mc.MechanicCertificationID, mct.MechanicCertificationType, mc.IssueDate, mc.ExpiryDate,
                    mc.RevocationDate, mc.Status, mc.StatusNotes
             FROM mechaniccertification mc
             JOIN mechaniccertificationtype mct ON mct.MechanicCertificationTypeID = mc.MechanicCertificationTypeID
             WHERE mc.MechanicID = :id
             ORDER BY mc.ExpiryDate DESC'
        );
        $stmt->execute(['id' => $mechanicId]);
        $certs = $stmt->fetchAll();
    }
}

// Q26: roster by certification type
$perPage = 10;
$page = currentPage('page');
$whereClause = "WHERE mc.Status IN ('Active', 'Reinstated') AND mc.ExpiryDate > CURDATE()
       AND (:certType = '' OR mct.MechanicCertificationTypeID = :certType)
       AND (:workshopId = '' OR w.WorkshopID = :workshopId)";
$filterParams = ['certType' => $certTypeFilter, 'workshopId' => $workshopFilter];

$countStmt = $pdo->prepare(
    "SELECT COUNT(*) FROM mechaniccertification mc
     JOIN mechanic m ON m.MechanicID = mc.MechanicID
     JOIN workshop w ON w.WorkshopID = m.WorkshopID
     JOIN mechaniccertificationtype mct ON mct.MechanicCertificationTypeID = mc.MechanicCertificationTypeID
     $whereClause"
);
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$roster = $pdo->prepare(
    "SELECT mct.MechanicCertificationType, m.MechanicID, m.FullName, w.Name AS WorkshopName, mc.ExpiryDate
     FROM mechaniccertification mc
     JOIN mechanic m ON m.MechanicID = mc.MechanicID
     JOIN workshop w ON w.WorkshopID = m.WorkshopID
     JOIN mechaniccertificationtype mct ON mct.MechanicCertificationTypeID = mc.MechanicCertificationTypeID
     $whereClause
     ORDER BY mct.MechanicCertificationType, m.FullName
     LIMIT $perPage OFFSET $offset"
);
$roster->execute($filterParams);
$roster = $roster->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mechanic Certifications</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Mechanic Certifications</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <h3>Manage a Mechanic's Certifications</h3>
    <form method="GET">
        <input type="text" name="mechanic_id" placeholder="Mechanic ID, e.g. ME-0001" value="<?= htmlspecialchars($mechanicId) ?>" required>
        <button type="submit">Look Up</button>
    </form>

    <?php if ($mechanicId !== '' && !$mechanic): ?>
        <p>No mechanic found with that ID.</p>
    <?php elseif ($mechanic): ?>
        <h4><?= htmlspecialchars($mechanic['FullName']) ?> (<?= htmlspecialchars($mechanic['MechanicID']) ?>)</h4>

        <strong>Issue New Certification</strong>
        <form method="POST">
            <input type="hidden" name="mechanic_id" value="<?= htmlspecialchars($mechanicId) ?>">
            <select name="cert_type_id" required>
                <?php foreach ($certTypes as $ct): ?>
                    <option value="<?= $ct['MechanicCertificationTypeID'] ?>"><?= htmlspecialchars($ct['MechanicCertificationType']) ?></option>
                <?php endforeach; ?>
            </select>
            Issue Date: <input type="date" name="issue_date" required>
            Expiry Date: <input type="date" name="expiry_date" required>
            <button type="submit" name="issue_cert" value="1">Issue</button>
        </form>

        <strong>Existing Certifications</strong>
        <?php if (count($certs) === 0): ?>
            <p>No certifications on record for this mechanic.</p>
        <?php else: ?>
            <table>
                <tr><th>Certification</th><th>Issued</th><th>Expires</th><th>Revoked</th><th>Status</th><th>Notes</th><th>Change Status</th></tr>
                <?php foreach ($certs as $c): ?>
                    <tr>
                        <td><?= htmlspecialchars($c['MechanicCertificationType']) ?></td>
                        <td><?= htmlspecialchars($c['IssueDate']) ?></td>
                        <td><?= htmlspecialchars($c['ExpiryDate']) ?></td>
                        <td><?= htmlspecialchars($c['RevocationDate'] ?? '') ?></td>
                        <td><?= htmlspecialchars($c['Status']) ?></td>
                        <td><?= htmlspecialchars($c['StatusNotes'] ?? '') ?></td>
                        <td>
                            <details>
                                <summary>Update</summary>
                                <form method="POST">
                                    <input type="hidden" name="cert_id" value="<?= htmlspecialchars($c['MechanicCertificationID']) ?>">
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

    <h3>Certification Roster (Active, Unexpired)</h3>
    <form method="GET">
        <select name="cert_type_filter">
            <option value="">All Certification Types</option>
            <?php foreach ($certTypes as $ct): ?>
                <option value="<?= $ct['MechanicCertificationTypeID'] ?>" <?= $certTypeFilter == $ct['MechanicCertificationTypeID'] ? 'selected' : '' ?>><?= htmlspecialchars($ct['MechanicCertificationType']) ?></option>
            <?php endforeach; ?>
        </select>
        <select name="workshop_filter">
            <option value="">All Workshops</option>
            <?php foreach ($workshops as $w): ?>
                <option value="<?= $w['WorkshopID'] ?>" <?= $workshopFilter == $w['WorkshopID'] ? 'selected' : '' ?>><?= htmlspecialchars($w['Name']) ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="mechanic_certifications.php">Clear</a>
    </form>
    <table>
        <tr><th>Certification</th><th>Mechanic</th><th>Workshop</th><th>Expires</th></tr>
        <?php foreach ($roster as $r): ?>
            <tr>
                <td><?= htmlspecialchars($r['MechanicCertificationType']) ?></td>
                <td><?= htmlspecialchars($r['FullName']) ?> (<?= htmlspecialchars($r['MechanicID']) ?>)</td>
                <td><?= htmlspecialchars($r['WorkshopName']) ?></td>
                <td><?= htmlspecialchars($r['ExpiryDate']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
