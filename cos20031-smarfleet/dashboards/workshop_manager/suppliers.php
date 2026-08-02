<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/pagination.php';

$partNumber = $_GET['part_number'] ?? '';
$primaryOnly = isset($_GET['primary_only']);
$supplierName = $_GET['supplier_name'] ?? '';

$parts = $pdo->query('SELECT PartNumber, PartName FROM part ORDER BY PartName')->fetchAll();

$perPage = 10;
$page = currentPage('page');

$whereClause = "WHERE (:partNumber = '' OR p.PartNumber = :partNumber)
       AND (:supplierName = '' OR s.SupplierName LIKE :supplierName)"
    . ($primaryOnly ? ' AND ps.IsPrimary = TRUE' : '');
$filterParams = ['partNumber' => $partNumber, 'supplierName' => $supplierName !== '' ? '%' . $supplierName . '%' : ''];

$countStmt = $pdo->prepare(
    "SELECT COUNT(*) FROM partsupplier ps
     JOIN part p ON p.PartNumber = ps.PartNumber
     JOIN supplier s ON s.SupplierID = ps.SupplierID
     $whereClause"
);
$countStmt->execute($filterParams);
$totalRows = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$stmt = $pdo->prepare(
    "SELECT p.PartNumber, p.PartName, s.SupplierID, s.SupplierName, s.ContactInfo, s.DeliveryLeadTime, ps.IsPrimary, ps.UnitCost
     FROM partsupplier ps
     JOIN part p ON p.PartNumber = ps.PartNumber
     JOIN supplier s ON s.SupplierID = ps.SupplierID
     $whereClause
     ORDER BY p.PartName, ps.IsPrimary DESC, ps.UnitCost ASC
     LIMIT $perPage OFFSET $offset"
);
$stmt->execute($filterParams);
$results = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Suppliers</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Supplier Pricing &amp; Lead Time</h2>

    <form method="GET">
        <select name="part_number">
            <option value="">All Parts</option>
            <?php foreach ($parts as $p): ?>
                <option value="<?= $p['PartNumber'] ?>" <?= $partNumber == $p['PartNumber'] ? 'selected' : '' ?>><?= htmlspecialchars($p['PartName']) ?></option>
            <?php endforeach; ?>
        </select>
        <label><input type="checkbox" name="primary_only" value="1" <?= $primaryOnly ? 'checked' : '' ?>> Primary supplier only</label>
        <input type="text" name="supplier_name" placeholder="Supplier name" value="<?= htmlspecialchars($supplierName) ?>">
        <button type="submit">Filter</button>
        <a href="suppliers.php">Clear</a>
    </form>

    <table>
        <tr><th>Part</th><th>Supplier</th><th>Contact</th><th>Lead Time (days)</th><th>Primary?</th><th>Unit Cost</th></tr>
        <?php foreach ($results as $r): ?>
            <tr>
                <td><?= htmlspecialchars($r['PartName']) ?></td>
                <td><?= htmlspecialchars($r['SupplierName']) ?></td>
                <td><?= htmlspecialchars($r['ContactInfo']) ?></td>
                <td><?= htmlspecialchars($r['DeliveryLeadTime']) ?></td>
                <td><?= $r['IsPrimary'] ? 'Primary' : 'Backup' ?></td>
                <td><?= number_format($r['UnitCost']) ?> VND</td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
