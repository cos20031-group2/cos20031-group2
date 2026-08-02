<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$manufacturer = $_GET['manufacturer'] ?? '';
$model = $_GET['model'] ?? '';

$manufacturers = $pdo->query('SELECT DISTINCT Manufacturer FROM vehicle ORDER BY Manufacturer')->fetchAll(PDO::FETCH_COLUMN);

$perPage = 10;
$page = currentPage('page');

$whereClause = "WHERE mj.TotalCost IS NOT NULL
       AND (:manufacturer = '' OR v.Manufacturer = :manufacturer)
       AND (:model = '' OR v.Model = :model)";
$filterParams = ['manufacturer' => $manufacturer, 'model' => $model];

$countStmt = $pdo->prepare(
    "SELECT COUNT(*) FROM (
        SELECT v.Manufacturer, v.Model FROM vehicle v JOIN maintenancejob mj ON mj.VIN = v.VIN
        $whereClause
        GROUP BY v.Manufacturer, v.Model
     ) AS sub"
);
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT
        v.Manufacturer, v.Model,
        COUNT(DISTINCT v.VIN) AS FleetCount,
        COUNT(mj.JobID) AS JobCount,
        SUM(mj.TotalCost) AS TotalCost,
        ROUND(AVG(mj.TotalCost), 2) AS AvgCostPerJob,
        ROUND(SUM(mj.TotalCost) / COUNT(DISTINCT v.VIN), 2) AS AvgCostPerVehicle
     FROM vehicle v
     JOIN maintenancejob mj ON mj.VIN = v.VIN
     $whereClause
     GROUP BY v.Manufacturer, v.Model
     ORDER BY AvgCostPerVehicle DESC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$results = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Maintenance Cost Comparison</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Maintenance Cost Comparison by Manufacturer / Model</h2>

    <form method="GET">
        <select name="manufacturer">
            <option value="">All Manufacturers</option>
            <?php foreach ($manufacturers as $m): ?>
                <option value="<?= htmlspecialchars($m) ?>" <?= $manufacturer === $m ? 'selected' : '' ?>><?= htmlspecialchars($m) ?></option>
            <?php endforeach; ?>
        </select>
        <input type="text" name="model" placeholder="Model" value="<?= htmlspecialchars($model) ?>">
        <button type="submit">Filter</button>
        <a href="cost_comparison.php">Clear</a>
    </form>

    <table>
        <tr><th>Manufacturer</th><th>Model</th><th>Fleet Count</th><th>Jobs</th><th>Total Cost</th><th>Avg Cost / Job</th><th>Avg Cost / Vehicle</th></tr>
        <?php foreach ($results as $r): ?>
            <tr>
                <td><?= htmlspecialchars($r['Manufacturer']) ?></td>
                <td><?= htmlspecialchars($r['Model']) ?></td>
                <td><?= htmlspecialchars($r['FleetCount']) ?></td>
                <td><?= htmlspecialchars($r['JobCount']) ?></td>
                <td><?= number_format($r['TotalCost']) ?> VND</td>
                <td><?= number_format($r['AvgCostPerJob']) ?> VND</td>
                <td><?= number_format($r['AvgCostPerVehicle']) ?> VND</td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
