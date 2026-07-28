<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Mechanic']);
require_once __DIR__ . '/../../config/db.php';

$mechanicId = $_SESSION['mechanic_id'];

$stmt = $pdo->prepare(
    'SELECT m.FullName, m.EmploymentStatus, w.Name AS WorkshopName
     FROM mechanic m
     JOIN workshop w ON w.WorkshopID = m.WorkshopID
     WHERE m.MechanicID = :id'
);
$stmt->execute(['id' => $mechanicId]);
$mechanic = $stmt->fetch();

$stmt = $pdo->prepare(
    'SELECT COUNT(*) FROM mechanicworksession WHERE MechanicID = :id AND EndTime IS NULL'
);
$stmt->execute(['id' => $mechanicId]);
$openSessions = $stmt->fetchColumn();

$stmt = $pdo->prepare(
    'SELECT COUNT(*) FROM mechaniccertification
     WHERE MechanicID = :id AND Status IN (\'Active\', \'Reinstated\') AND ExpiryDate > CURDATE()'
);
$stmt->execute(['id' => $mechanicId]);
$activeCertCount = $stmt->fetchColumn();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mechanic Dashboard</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <h2><?= htmlspecialchars($mechanic['FullName']) ?></h2>
    <p>
        Mechanic ID: <?= htmlspecialchars($mechanicId) ?> &nbsp;|&nbsp;
        Workshop: <?= htmlspecialchars($mechanic['WorkshopName']) ?> &nbsp;|&nbsp;
        Employment: <?= htmlspecialchars($mechanic['EmploymentStatus']) ?>
    </p>

    <div class="card-grid">
        <div class="card">
            <h3>Open Work Sessions</h3>
            <div class="stat-value"><?= htmlspecialchars($openSessions) ?></div>
        </div>
        <div class="card">
            <h3>Active Certifications</h3>
            <div class="stat-value"><?= htmlspecialchars($activeCertCount) ?></div>
        </div>
    </div>

    <div class="card-grid">
        <a class="card" href="work_sessions.php">
            <h3>Work Sessions</h3>
            <p>View, log, and close work sessions on maintenance activities.</p>
        </a>
        <a class="card" href="maintenance_history.php">
            <h3>Vehicle Maintenance History</h3>
            <p>Look up diagnostic records and previous repairs for any vehicle.</p>
        </a>
        <a class="card" href="certifications.php">
            <h3>My Certifications</h3>
            <p>View certification status and expiry dates.</p>
        </a>
    </div>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
