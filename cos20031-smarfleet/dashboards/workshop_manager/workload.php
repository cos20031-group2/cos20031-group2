<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';

// Q16: Workshop workload
$workshops = $pdo->query(
    "SELECT
        w.WorkshopID, w.Name, d.DepotName,
        SUM(CASE WHEN mj.DateClosed IS NULL THEN 1 ELSE 0 END) AS OpenJobs,
        COUNT(mj.JobID) AS TotalJobsAllTime,
        AVG(CASE WHEN mj.DateClosed IS NOT NULL
                 THEN TIMESTAMPDIFF(HOUR, mj.DateOpened, mj.DateClosed) END) AS AvgTurnaroundHours
     FROM workshop w
     JOIN depot d ON d.DepotID = w.DepotID
     LEFT JOIN maintenancejob mj ON mj.WorkshopID = w.WorkshopID
     GROUP BY w.WorkshopID, w.Name, d.DepotName
     ORDER BY OpenJobs DESC"
)->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Workshop Workload</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Workshop Workload</h2>

    <table>
        <tr><th>Workshop</th><th>Depot</th><th>Open Jobs</th><th>Total Jobs (All Time)</th><th>Avg Turnaround (hrs)</th></tr>
        <?php foreach ($workshops as $w): ?>
            <tr>
                <td><?= htmlspecialchars($w['Name']) ?></td>
                <td><?= htmlspecialchars($w['DepotName']) ?></td>
                <td class="<?= $w['OpenJobs'] > 5 ? 'score-warning' : '' ?>"><?= htmlspecialchars($w['OpenJobs']) ?></td>
                <td><?= htmlspecialchars($w['TotalJobsAllTime']) ?></td>
                <td><?= $w['AvgTurnaroundHours'] !== null ? htmlspecialchars(round($w['AvgTurnaroundHours'], 1)) : 'N/A' ?></td>
            </tr>
        <?php endforeach; ?>
    </table>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
