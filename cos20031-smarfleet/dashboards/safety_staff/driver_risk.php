<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Safety Staff']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$perPage = 10;
$month = $_GET['month'] ?? date('n');
$year  = $_GET['year'] ?? date('Y');

// --- Section 1: high-risk drivers (Q2a) ---
$riskPage = currentPage('risk_page');
$countStmt = $pdo->prepare('SELECT COUNT(*) FROM drivermonthlysafetyscore WHERE Month = :month AND Year = :year');
$countStmt->execute(['month' => $month, 'year' => $year]);
$totalRisk = (int)$countStmt->fetchColumn();
$totalRiskPages = max(1, (int)ceil($totalRisk / $perPage));
$riskPage = min($riskPage, $totalRiskPages);
$riskOffset = ($riskPage - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT dr.DriverID, dr.FullName, d.DepotName, dms.DriverMonthlySafetyScoreID, dms.Month, dms.Year, dms.Score,
            (SELECT COUNT(*) FROM safetyevent se
             WHERE se.DriverID = dr.DriverID
               AND MONTH(se.EventTimestamp) = dms.Month
               AND YEAR(se.EventTimestamp) = dms.Year) AS EventsThisMonth
     FROM drivermonthlysafetyscore dms
     JOIN driver dr ON dr.DriverID = dms.DriverID
     JOIN depot d ON d.DepotID = dms.DepotID
     WHERE dms.Month = :month AND dms.Year = :year
     ORDER BY dms.Score ASC
     LIMIT $perPage OFFSET $riskOffset"
);
$stmt->execute(['month' => $month, 'year' => $year]);
$riskDrivers = $stmt->fetchAll();

// --- Penalty breakdown drill-down (small, unpaginated) ---
$penalties = [];
$expandedScoreId = $_GET['score_id'] ?? '';
if ($expandedScoreId !== '') {
    $stmt = $pdo->prepare(
        'SELECT pr.RuleType, pr.RuleDescription, dsp.EventID, dsp.PointsDeducted, dsp.DateApplied
         FROM driverscorepenalty dsp
         JOIN penaltyrule pr ON pr.PenaltyRuleID = dsp.PenaltyRuleID
         WHERE dsp.DriverMonthlySafetyScoreID = :id
         ORDER BY dsp.DateApplied'
    );
    $stmt->execute(['id' => $expandedScoreId]);
    $penalties = $stmt->fetchAll();
}

// --- Section 2: drivers ranked by event type (Q10) ---
$rankPage = currentPage('rank_page');
$rankEventType = $_GET['rank_event_type'] ?? 'Excessive speeding';

$countStmt = $pdo->prepare(
    'SELECT COUNT(*) FROM (
        SELECT se.DriverID FROM safetyevent se
        JOIN eventtype et ON et.EventTypeID = se.EventTypeID
        WHERE et.EventType = :eventType
        GROUP BY se.DriverID
     ) AS sub'
);
$countStmt->execute(['eventType' => $rankEventType]);
$totalRank = (int)$countStmt->fetchColumn();
$totalRankPages = max(1, (int)ceil($totalRank / $perPage));
$rankPage = min($rankPage, $totalRankPages);
$rankOffset = ($rankPage - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT dr.DriverID, dr.FullName, COUNT(*) AS EventCount
     FROM safetyevent se
     JOIN driver dr ON dr.DriverID = se.DriverID
     JOIN eventtype et ON et.EventTypeID = se.EventTypeID
     WHERE et.EventType = :eventType
     GROUP BY dr.DriverID, dr.FullName
     ORDER BY EventCount DESC
     LIMIT $perPage OFFSET $rankOffset"
);
$stmt->execute(['eventType' => $rankEventType]);
$rankedDrivers = $stmt->fetchAll();

$eventTypes = $pdo->query('SELECT EventType FROM eventtype ORDER BY EventType')->fetchAll();

// --- Section 3: drivers requiring retraining (Q7) ---
$retrainPage = currentPage('retrain_page');
$totalRetrain = (int)$pdo->query(
    "SELECT COUNT(DISTINCT DriverID) FROM coachingrecord
     WHERE CoachingType = 'Retraining' AND Outcome <> 'Passed'"
)->fetchColumn();
$totalRetrainPages = max(1, (int)ceil($totalRetrain / $perPage));
$retrainPage = min($retrainPage, $totalRetrainPages);
$retrainOffset = ($retrainPage - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT DISTINCT cr.DriverID, dr.FullName, cr.CoachingDate, cr.Outcome
     FROM coachingrecord cr
     JOIN driver dr ON dr.DriverID = cr.DriverID
     WHERE cr.CoachingType = 'Retraining' AND cr.Outcome <> 'Passed'
     ORDER BY cr.CoachingDate DESC
     LIMIT $perPage OFFSET $retrainOffset"
);
$stmt->execute();
$retraining = $stmt->fetchAll();

function scoreClass(float $score): string
{
    if ($score <= 50) return 'score-critical';
    if ($score <= 75) return 'score-warning';
    return 'score-good';
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Driver Risk</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="safety_staff_index.php">&larr; Back to dashboard</a>
    <h2>Driver Risk</h2>

    <h3>Monthly Safety Scores -- <?= htmlspecialchars($month) ?>/<?= htmlspecialchars($year) ?></h3>
    <form method="GET">
        Month: <input type="number" name="month" min="1" max="12" value="<?= htmlspecialchars($month) ?>">
        Year: <input type="number" name="year" value="<?= htmlspecialchars($year) ?>">
        <button type="submit">View</button>
    </form>
    <table>
        <tr><th>Driver</th><th>Depot</th><th>Score</th><th>Events This Month</th><th></th></tr>
        <?php foreach ($riskDrivers as $r): ?>
            <tr>
                <td><?= htmlspecialchars($r['FullName']) ?> (<?= htmlspecialchars($r['DriverID']) ?>)</td>
                <td><?= htmlspecialchars($r['DepotName']) ?></td>
                <td class="<?= scoreClass((float)$r['Score']) ?>"><?= htmlspecialchars($r['Score']) ?></td>
                <td><?= htmlspecialchars($r['EventsThisMonth']) ?></td>
                <td><a href="?month=<?= $month ?>&year=<?= $year ?>&score_id=<?= $r['DriverMonthlySafetyScoreID'] ?>&risk_page=<?= $riskPage ?>&rank_page=<?= $rankPage ?>&retrain_page=<?= $retrainPage ?>#breakdown">View Penalties</a></td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($riskPage, $totalRiskPages, 'risk_page') ?>

    <?php if ($expandedScoreId !== ''): ?>
        <h3 id="breakdown">Penalty Breakdown</h3>
        <?php if (count($penalties) === 0): ?>
            <p>No penalties recorded for this driver-month.</p>
        <?php else: ?>
            <table>
                <tr><th>Rule Type</th><th>Description</th><th>Event</th><th>Points</th><th>Date Applied</th></tr>
                <?php foreach ($penalties as $p): ?>
                    <tr>
                        <td><?= htmlspecialchars($p['RuleType']) ?></td>
                        <td><?= htmlspecialchars($p['RuleDescription']) ?></td>
                        <td><?= htmlspecialchars($p['EventID'] ?? '') ?></td>
                        <td><?= htmlspecialchars($p['PointsDeducted']) ?></td>
                        <td><?= htmlspecialchars($p['DateApplied']) ?></td>
                    </tr>
                <?php endforeach; ?>
            </table>
        <?php endif; ?>
    <?php endif; ?>

    <h3>Drivers Ranked by Event Type</h3>
    <form method="GET">
        <input type="hidden" name="month" value="<?= htmlspecialchars($month) ?>">
        <input type="hidden" name="year" value="<?= htmlspecialchars($year) ?>">
        <select name="rank_event_type">
            <?php foreach ($eventTypes as $et): ?>
                <option value="<?= htmlspecialchars($et['EventType']) ?>" <?= $rankEventType === $et['EventType'] ? 'selected' : '' ?>>
                    <?= htmlspecialchars($et['EventType']) ?>
                </option>
            <?php endforeach; ?>
        </select>
        <button type="submit">Rank</button>
    </form>
    <table>
        <tr><th>Driver</th><th>Event Count</th></tr>
        <?php foreach ($rankedDrivers as $rd): ?>
            <tr>
                <td><?= htmlspecialchars($rd['FullName']) ?> (<?= htmlspecialchars($rd['DriverID']) ?>)</td>
                <td><?= htmlspecialchars($rd['EventCount']) ?></td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($rankPage, $totalRankPages, 'rank_page') ?>

    <h3>Drivers Requiring Retraining</h3>
    <?php if (count($retraining) === 0): ?>
        <p>No drivers currently require retraining.</p>
    <?php else: ?>
        <table>
            <tr><th>Driver</th><th>Coaching Date</th><th>Outcome</th></tr>
            <?php foreach ($retraining as $rt): ?>
                <tr>
                    <td><?= htmlspecialchars($rt['FullName']) ?> (<?= htmlspecialchars($rt['DriverID']) ?>)</td>
                    <td><?= htmlspecialchars($rt['CoachingDate']) ?></td>
                    <td><?= htmlspecialchars($rt['Outcome']) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
        <?= paginationControls($retrainPage, $totalRetrainPages, 'retrain_page') ?>
    <?php endif; ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
