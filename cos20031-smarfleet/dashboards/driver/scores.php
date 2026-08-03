<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Driver']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$driverId = $_SESSION['driver_id'];

$perPage = 10;
$page = currentPage('page');

$countStmt = $pdo->prepare('SELECT COUNT(*) FROM drivermonthlysafetyscore WHERE DriverID = :id');
$countStmt->execute(['id' => $driverId]);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT Month, Year, Score FROM drivermonthlysafetyscore
     WHERE DriverID = :id
     ORDER BY Year DESC, Month DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute(['id' => $driverId]);
$scores = $stmt->fetchAll();

function scoreClass(float $score): string
{
    if ($score <= 50) return 'score-critical';
    if ($score <= 75) return 'score-warning';
    return 'score-good';
}

$monthNames = [1=>'January',2=>'February',3=>'March',4=>'April',5=>'May',6=>'June',
               7=>'July',8=>'August',9=>'September',10=>'October',11=>'November',12=>'December'];
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Monthly Safety Scores</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="driver_index.php">&larr; Back to dashboard</a>
    <h2>Monthly Safety Scores</h2>

    <?php if (count($scores) === 0): ?>
        <p>No monthly scores recorded yet.</p>
    <?php else: ?>
        <table>
            <tr>
                <th>Month</th>
                <th>Score</th>
                <th>Status</th>
            </tr>
            <?php foreach ($scores as $s): ?>
                <tr>
                    <td><?= htmlspecialchars($monthNames[(int)$s['Month']]) ?> <?= htmlspecialchars($s['Year']) ?></td>
                    <td class="<?= scoreClass((float)$s['Score']) ?>"><?= htmlspecialchars($s['Score']) ?></td>
                    <td>
                        <?php if ($s['Score'] <= 50): ?>
                            Retraining required
                        <?php elseif ($s['Score'] <= 75): ?>
                            Coaching required
                        <?php else: ?>
                            Good standing
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($page, $totalPages, 'page') ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
