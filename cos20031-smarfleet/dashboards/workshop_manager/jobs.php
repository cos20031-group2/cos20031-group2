<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';
require_once __DIR__ . '/../../includes/pagination.php';

$message = '';
$error = '';

function nextJobId(PDO $pdo): string
{
    $max = $pdo->query("SELECT MAX(JobID) FROM maintenancejob WHERE JobID LIKE 'MJOB-%'")->fetchColumn();
    $nextNum = $max ? ((int)substr($max, 5)) + 1 : 1;
    return 'MJOB-' . str_pad((string)$nextNum, 6, '0', STR_PAD_LEFT);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['create_job'])) {
            $newId = nextJobId($pdo);
            $scheduleId = $_POST['schedule_id'] !== '' ? $_POST['schedule_id'] : null;
            $vin = $_POST['vin'];

            // If a scheduled service was picked, use its VIN rather than trusting the manual field.
            if ($scheduleId !== null) {
                $s = $pdo->prepare('SELECT VIN FROM scheduledservice WHERE ScheduleID = :id');
                $s->execute(['id' => $scheduleId]);
                $vin = $s->fetchColumn();
            }

            $stmt = $pdo->prepare(
                'INSERT INTO maintenancejob (JobID, VIN, WorkshopID, ScheduleID, DateOpened, Downtime)
                 VALUES (:jobId, :vin, :workshop, :scheduleId, NOW(), 0)'
            );
            $stmt->execute([
                'jobId' => $newId, 'vin' => $vin, 'workshop' => $_POST['workshop_id'], 'scheduleId' => $scheduleId,
            ]);
            $message = "Job opened ($newId).";
        } elseif (isset($_POST['close_job'])) {
            $stmt = $pdo->prepare(
                'UPDATE maintenancejob SET DateClosed = NOW(), Downtime = :downtime, TotalCost = :totalCost
                 WHERE JobID = :id AND DateClosed IS NULL'
            );
            $stmt->execute([
                'downtime' => $_POST['downtime'], 'totalCost' => $_POST['total_cost'], 'id' => $_POST['job_id'],
            ]);
            $message = 'Job closed.';
        }
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$workshops = $pdo->query('SELECT WorkshopID, Name FROM workshop ORDER BY Name')->fetchAll();
$openSchedules = $pdo->query(
    "SELECT ss.ScheduleID, ss.VIN, v.RegistrationNumber, ss.ScheduledDate, ss.Reason
     FROM scheduledservice ss JOIN vehicle v ON v.VIN = ss.VIN
     WHERE ss.Status IN ('Scheduled', 'In Progress')
     ORDER BY ss.ScheduledDate"
)->fetchAll();

$statusFilter = $_GET['status'] ?? 'open';
$workshopFilter = $_GET['workshop_id'] ?? '';
$vinFilter = $_GET['vin'] ?? '';

$perPage = 10;
$page = currentPage('page');

$statusCondition = $statusFilter === 'open' ? 'mj.DateClosed IS NULL'
    : ($statusFilter === 'closed' ? 'mj.DateClosed IS NOT NULL' : '1=1');

$whereClause = "WHERE $statusCondition
       AND (:workshopId = '' OR mj.WorkshopID = :workshopId)
       AND (:vin = '' OR mj.VIN = :vin)";
$filterParams = ['workshopId' => $workshopFilter, 'vin' => $vinFilter];

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM maintenancejob mj $whereClause");
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT mj.JobID, mj.VIN, v.RegistrationNumber, w.Name AS WorkshopName,
            mj.DateOpened, mj.DateClosed, mj.Downtime, mj.TotalCost
     FROM maintenancejob mj
     JOIN vehicle v ON v.VIN = mj.VIN
     JOIN workshop w ON w.WorkshopID = mj.WorkshopID
     $whereClause
     ORDER BY mj.DateOpened DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$jobs = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Maintenance Jobs</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Maintenance Jobs</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <h3>Open New Job</h3>
    <form method="POST">
        Link to a pending scheduled service (optional):
        <select name="schedule_id">
            <option value="">-- None (ad-hoc job) --</option>
            <?php foreach ($openSchedules as $s): ?>
                <option value="<?= $s['ScheduleID'] ?>">
                    <?= htmlspecialchars($s['ScheduledDate']) ?> -- <?= htmlspecialchars($s['RegistrationNumber']) ?> -- <?= htmlspecialchars($s['Reason']) ?>
                </option>
            <?php endforeach; ?>
        </select><br>
        VIN (only used if no scheduled service selected above): <input type="text" name="vin" maxlength="17" placeholder="17-character VIN"><br>
        Workshop:
        <select name="workshop_id" required>
            <?php foreach ($workshops as $w): ?>
                <option value="<?= $w['WorkshopID'] ?>"><?= htmlspecialchars($w['Name']) ?></option>
            <?php endforeach; ?>
        </select><br><br>
        <button type="submit" name="create_job" value="1">Open Job</button>
    </form>
    <p><em>A vehicle can only have one open job at a time; it moves to "Under Maintenance" automatically.</em></p>

    <h3>Jobs</h3>
    <form method="GET">
        <select name="status">
            <option value="open" <?= $statusFilter === 'open' ? 'selected' : '' ?>>Open</option>
            <option value="closed" <?= $statusFilter === 'closed' ? 'selected' : '' ?>>Closed</option>
            <option value="all" <?= $statusFilter === 'all' ? 'selected' : '' ?>>All</option>
        </select>
        <select name="workshop_id">
            <option value="">All Workshops</option>
            <?php foreach ($workshops as $w): ?>
                <option value="<?= $w['WorkshopID'] ?>" <?= $workshopFilter == $w['WorkshopID'] ? 'selected' : '' ?>><?= htmlspecialchars($w['Name']) ?></option>
            <?php endforeach; ?>
        </select>
        <input type="text" name="vin" placeholder="VIN" value="<?= htmlspecialchars($vinFilter) ?>">
        <button type="submit">Filter</button>
        <a href="jobs.php">Clear</a>
    </form>

    <p><?= htmlspecialchars($totalRows) ?> job(s)</p>

    <table>
        <tr><th>Job ID</th><th>Vehicle</th><th>Workshop</th><th>Opened</th><th>Closed</th><th>Downtime (hrs)</th><th>Total Cost</th><th></th></tr>
        <?php foreach ($jobs as $j): ?>
            <tr>
                <td><?= htmlspecialchars($j['JobID']) ?></td>
                <td><?= htmlspecialchars($j['RegistrationNumber']) ?></td>
                <td><?= htmlspecialchars($j['WorkshopName']) ?></td>
                <td><?= htmlspecialchars($j['DateOpened']) ?></td>
                <td><?= htmlspecialchars($j['DateClosed'] ?? 'Open') ?></td>
                <td><?= htmlspecialchars($j['Downtime']) ?></td>
                <td><?= $j['TotalCost'] !== null ? number_format($j['TotalCost']) . ' VND' : '' ?></td>
                <td>
                    <a href="job_detail.php?job=<?= urlencode($j['JobID']) ?>">View / Add Activities</a>
                    <?php if ($j['DateClosed'] === null): ?>
                        <details>
                            <summary>Close Job</summary>
                            <form method="POST">
                                <input type="hidden" name="job_id" value="<?= htmlspecialchars($j['JobID']) ?>">
                                Downtime (hrs): <input type="number" step="0.01" name="downtime" required>
                                Total Cost (VND): <input type="number" name="total_cost" required>
                                <button type="submit" name="close_job" value="1">Close</button>
                            </form>
                        </details>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
