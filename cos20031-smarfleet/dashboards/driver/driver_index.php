<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Driver']);
require_once __DIR__ . '/../../config/db.php';

$driverId = $_SESSION['driver_id'];

$stmt = $pdo->prepare('SELECT FullName, EmploymentStatus, DrivingEligibility FROM driver WHERE DriverID = :id');
$stmt->execute(['id' => $driverId]);
$driver = $stmt->fetch();

$now = new DateTime();
$stmt = $pdo->prepare(
    'SELECT Score FROM drivermonthlysafetyscore
     WHERE DriverID = :id AND Month = :month AND Year = :year'
);
$stmt->execute(['id' => $driverId, 'month' => $now->format('n'), 'year' => $now->format('Y')]);
$currentScore = $stmt->fetchColumn();

$stmt = $pdo->prepare(
    'SELECT COUNT(*) FROM drivercertification
     WHERE DriverID = :id AND Status IN (\'Active\', \'Reinstated\') AND ExpiryDate > CURDATE()'
);
$stmt->execute(['id' => $driverId]);
$activeCertCount = $stmt->fetchColumn();

$scoreClass = 'score-good';
if ($currentScore !== false && $currentScore <= 50) {
    $scoreClass = 'score-critical';
} elseif ($currentScore !== false && $currentScore <= 75) {
    $scoreClass = 'score-warning';
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Driver Dashboard</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <h2><?= htmlspecialchars($driver['FullName']) ?></h2>
    <p>
        Driver ID: <?= htmlspecialchars($driverId) ?> &nbsp;|&nbsp;
        Employment: <?= htmlspecialchars($driver['EmploymentStatus']) ?> &nbsp;|&nbsp;
        Driving Eligibility: <?= htmlspecialchars($driver['DrivingEligibility']) ?>
    </p>

    <div class="card-grid">
        <div class="card">
            <h3>This Month's Safety Score</h3>
            <div class="stat-value <?= $scoreClass ?>">
                <?= $currentScore !== false ? htmlspecialchars($currentScore) : 'N/A' ?>
            </div>
        </div>
        <div class="card">
            <h3>Active Certifications</h3>
            <div class="stat-value"><?= htmlspecialchars($activeCertCount) ?></div>
        </div>
    </div>

    <div class="card-grid">
        <a class="card" href="safety_history.php">
            <h3>Safety Event History</h3>
            <p>View all recorded safety events and their review status.</p>
        </a>
        <a class="card" href="scores.php">
            <h3>Monthly Safety Scores</h3>
            <p>Track your safety score over time.</p>
        </a>
        <a class="card" href="certifications.php">
            <h3>My Certifications</h3>
            <p>View licence and certification status and expiry dates.</p>
        </a>
    </div>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
