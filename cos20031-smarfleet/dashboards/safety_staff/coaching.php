<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Safety Staff']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['record_outcome'])) {
    $outcome = $_POST['outcome'];
    $needsCompletionDate = in_array($outcome, ['Passed', 'Failed'], true);

    try {
        $stmt = $pdo->prepare(
            'UPDATE coachingrecord
             SET Outcome = :outcome, CompletionDate = :completionDate
             WHERE CoachingRecordID = :id'
        );
        $stmt->execute([
            'outcome' => $outcome,
            'completionDate' => $needsCompletionDate ? ($_POST['completion_date'] ?: date('Y-m-d')) : null,
            'id' => $_POST['coaching_record_id'],
        ]);
        $message = 'Outcome recorded.';
    } catch (PDOException $e) {
        $error = $e->getMessage();
    }
}

$driverId = $_GET['driver_id'] ?? '';
$outcomeFilter = $_GET['outcome'] ?? '';

$perPage = 10;
$page = currentPage('page');

$whereClause = 'WHERE (:driverId = \'\' OR cr.DriverID = :driverId)
       AND (:outcome = \'\' OR cr.Outcome = :outcome)';
$filterParams = ['driverId' => $driverId, 'outcome' => $outcomeFilter];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM coachingrecord cr $whereClause");
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT cr.CoachingRecordID, cr.DriverID, dr.FullName, cr.CoachingType,
            cr.CoachingDate, cr.CompletionDate, cr.Outcome
     FROM coachingrecord cr
     JOIN driver dr ON dr.DriverID = cr.DriverID
     $whereClause
     ORDER BY cr.CoachingDate DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$records = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Coaching Records</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="safety_staff_index.php">&larr; Back to dashboard</a>
    <h2>Coaching Records</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <form method="GET">
        <input type="text" name="driver_id" placeholder="Driver ID" value="<?= htmlspecialchars($driverId) ?>">
        <select name="outcome">
            <option value="">All Outcomes</option>
            <?php foreach (['Pending', 'In Progress', 'Passed', 'Failed'] as $o): ?>
                <option value="<?= $o ?>" <?= $outcomeFilter === $o ? 'selected' : '' ?>><?= $o ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Filter</button>
        <a href="coaching.php">Clear</a>
    </form>

    <table>
        <tr><th>Driver</th><th>Type</th><th>Coaching Date</th><th>Completion Date</th><th>Outcome</th><th>Record Outcome</th></tr>
        <?php foreach ($records as $r): ?>
            <tr>
                <td><?= htmlspecialchars($r['FullName']) ?> (<?= htmlspecialchars($r['DriverID']) ?>)</td>
                <td><?= htmlspecialchars($r['CoachingType']) ?></td>
                <td><?= htmlspecialchars($r['CoachingDate']) ?></td>
                <td><?= htmlspecialchars($r['CompletionDate'] ?? '') ?></td>
                <td><?= htmlspecialchars($r['Outcome']) ?></td>
                <td>
                    <?php if (in_array($r['Outcome'], ['Pending', 'In Progress'], true)): ?>
                        <form method="POST">
                            <input type="hidden" name="coaching_record_id" value="<?= htmlspecialchars($r['CoachingRecordID']) ?>">
                            <select name="outcome">
                                <option value="In Progress">In Progress</option>
                                <option value="Passed">Passed</option>
                                <option value="Failed">Failed</option>
                            </select>
                            <input type="date" name="completion_date">
                            <button type="submit" name="record_outcome" value="1">Save</button>
                        </form>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
