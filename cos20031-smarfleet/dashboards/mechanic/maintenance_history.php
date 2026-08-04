<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Mechanic']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$registration = trim($_GET['registration'] ?? '');
$history = [];
$vehicle = null;
$totalPages = 1;
$page = 1;

if ($registration !== '') {
    $stmt = $pdo->prepare('SELECT VIN, RegistrationNumber, Model, Manufacturer FROM vehicle WHERE RegistrationNumber = :reg');
    $stmt->execute(['reg' => $registration]);
    $vehicle = $stmt->fetch();

    if ($vehicle) {
        $perPage = 10;
        $page = currentPage('page');

        $countStmt = $pdo->prepare('SELECT COUNT(*) FROM maintenanceactivity ma JOIN maintenancejob mj ON mj.JobID = ma.JobID WHERE mj.VIN = :vin');
        $countStmt->execute(['vin' => $vehicle['VIN']]);
        $totalRows = (int)$countStmt->fetchColumn();
        $totalPages = max(1, (int)ceil($totalRows / $perPage));
        $page = min($page, $totalPages);
        $offset = ($page - 1) * $perPage;

        // Q27 (6_business_queries.sql): vehicle maintenance / diagnostic / repair history
        $stmt = $pdo->prepare(
            "SELECT mj.JobID, mj.DateOpened, mj.DateClosed, w.Name AS WorkshopName,
                    ma.ActivityID, at.ActivityType, ma.DiagnosticResult,
                    ma.RepeatedFaultFlag, ma.WarrantyFlag,
                    pa.AlertID, aty.AlertType AS LinkedAlertType
             FROM maintenancejob mj
             JOIN workshop w ON w.WorkshopID = mj.WorkshopID
             JOIN maintenanceactivity ma ON ma.JobID = mj.JobID
             JOIN activitytype at ON at.ActivityTypeID = ma.ActivityTypeID
             LEFT JOIN predictivealert pa ON pa.AlertID = ma.LinkedAlertID
             LEFT JOIN alerttype aty ON aty.AlertTypeID = pa.AlertTypeID
             WHERE mj.VIN = :vin
             ORDER BY mj.DateOpened DESC, ma.ActivityID
             LIMIT $perPage OFFSET $offset"
        );
        $stmt->execute(['vin' => $vehicle['VIN']]);
        $history = $stmt->fetchAll();
    }
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Vehicle Maintenance History</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="mechanic_index.php">&larr; Back to dashboard</a>
    <h2>Vehicle Maintenance History</h2>

    <form method="GET">
        <label>Registration Number:
            <input type="text" name="registration" value="<?= htmlspecialchars($registration) ?>" placeholder="e.g. 84V-244.44" required>
        </label>
        <button type="submit">Search</button>
    </form>

    <?php if ($registration !== '' && !$vehicle): ?>
        <p>No vehicle found with that registration number.</p>
    <?php elseif ($vehicle): ?>
        <h3><?= htmlspecialchars($vehicle['Manufacturer']) ?> <?= htmlspecialchars($vehicle['Model']) ?>
            (<?= htmlspecialchars($vehicle['RegistrationNumber']) ?>)</h3>

        <?php if (count($history) === 0): ?>
            <p>No maintenance history recorded for this vehicle.</p>
        <?php else: ?>
            <table>
                <tr>
                    <th>Job</th>
                    <th>Opened</th>
                    <th>Closed</th>
                    <th>Workshop</th>
                    <th>Activity Type</th>
                    <th>Diagnostic Result</th>
                    <th>Repeat Fault</th>
                    <th>Warranty</th>
                    <th>Linked Alert</th>
                </tr>
                <?php foreach ($history as $h): ?>
                    <tr>
                        <td><?= htmlspecialchars($h['JobID']) ?></td>
                        <td><?= htmlspecialchars($h['DateOpened']) ?></td>
                        <td><?= htmlspecialchars($h['DateClosed'] ?? 'Open') ?></td>
                        <td><?= htmlspecialchars($h['WorkshopName']) ?></td>
                        <td><?= htmlspecialchars($h['ActivityType']) ?></td>
                        <td><?= htmlspecialchars($h['DiagnosticResult'] ?? '') ?></td>
                        <td><?= $h['RepeatedFaultFlag'] ? 'Yes' : 'No' ?></td>
                        <td><?= $h['WarrantyFlag'] ? 'Yes' : 'No' ?></td>
                        <td><?= htmlspecialchars($h['LinkedAlertType'] ?? '') ?></td>
                    </tr>
                <?php endforeach; ?>
            </table>
            <?= paginationControls($page, $totalPages, 'page') ?>
        <?php endif; ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
