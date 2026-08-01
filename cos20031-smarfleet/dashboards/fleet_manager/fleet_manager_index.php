<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Fleet Manager']);
require_once __DIR__ . '/../../config/db.php';

$vehicleCounts = $pdo->query(
    'SELECT vs.VehicleStatus, COUNT(*) AS Total
     FROM vehicle v JOIN vehiclestatus vs ON vs.VehicleStatusID = v.OperationalStatus
     GROUP BY vs.VehicleStatus'
)->fetchAll(PDO::FETCH_KEY_PAIR);

$driverTotal = $pdo->query("SELECT COUNT(*) FROM driver WHERE EmploymentStatus = 'Active'")->fetchColumn();
$suspendedDrivers = $pdo->query("SELECT COUNT(*) FROM driver WHERE DrivingEligibility = 'Suspended'")->fetchColumn();
$pendingAssignments = $pdo->query("SELECT COUNT(*) FROM vehicleassignment WHERE AssignmentStatus = 'Pending'")->fetchColumn();
$activeAssignments = $pdo->query("SELECT COUNT(*) FROM vehicleassignment WHERE AssignmentStatus = 'In Operation'")->fetchColumn();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Fleet Manager Dashboard</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <h2>Fleet Manager Dashboard</h2>

    <div class="card-grid">
        <?php foreach ($vehicleCounts as $status => $count): ?>
            <div class="card">
                <h3><?= htmlspecialchars($status) ?></h3>
                <div class="stat-value"><?= htmlspecialchars($count) ?></div>
            </div>
        <?php endforeach; ?>
    </div>

    <div class="card-grid">
        <div class="card">
            <h3>Active Drivers</h3>
            <div class="stat-value"><?= htmlspecialchars($driverTotal) ?></div>
        </div>
        <div class="card">
            <h3>Suspended Drivers</h3>
            <div class="stat-value score-critical"><?= htmlspecialchars($suspendedDrivers) ?></div>
        </div>
        <div class="card">
            <h3>Pending Assignments</h3>
            <div class="stat-value score-warning"><?= htmlspecialchars($pendingAssignments) ?></div>
        </div>
        <div class="card">
            <h3>Active Assignments</h3>
            <div class="stat-value score-good"><?= htmlspecialchars($activeAssignments) ?></div>
        </div>
    </div>

    <div class="card-grid">
        <a class="card" href="vehicles.php">
            <h3>Vehicles</h3>
            <p>Add, edit, and manage the vehicle fleet.</p>
        </a>
        <a class="card" href="drivers.php">
            <h3>Drivers</h3>
            <p>Add, edit, and manage driver records.</p>
        </a>
        <a class="card" href="certifications.php">
            <h3>Driver Certifications</h3>
            <p>Issue, revoke, void, or reinstate driver certifications.</p>
        </a>
        <a class="card" href="assignments.php">
            <h3>Vehicle Assignments</h3>
            <p>Book, start, complete, or cancel vehicle assignments.</p>
        </a>
        <a class="card" href="certification_requirements.php">
            <h3>Certification Requirements</h3>
            <p>Reference matrix: which certifications each vehicle category requires.</p>
        </a>
    </div>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
