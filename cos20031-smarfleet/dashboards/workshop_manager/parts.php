<?php
session_start();
require_once __DIR__ . '/../../includes/require_role.php';
requireRole(['Workshop Manager']);
require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../includes/errors.php';
require_once __DIR__ . '/../../includes/pagination.php';

$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        if (isset($_POST['add_part'])) {
            $stmt = $pdo->prepare(
                'INSERT INTO part (PartName, Description, CurrentStock, ReorderThreshold, UnitPrice)
                 VALUES (:name, :description, :stock, :threshold, :price)'
            );
            $stmt->execute([
                'name' => $_POST['part_name'], 'description' => $_POST['description'],
                'stock' => $_POST['current_stock'], 'threshold' => $_POST['reorder_threshold'], 'price' => $_POST['unit_price'],
            ]);
            $message = 'Part added.';
        } elseif (isset($_POST['update_part'])) {
            $stmt = $pdo->prepare(
                'UPDATE part SET PartName = :name, Description = :description, ReorderThreshold = :threshold, UnitPrice = :price
                 WHERE PartNumber = :pn'
            );
            $stmt->execute([
                'name' => $_POST['part_name'], 'description' => $_POST['description'],
                'threshold' => $_POST['reorder_threshold'], 'price' => $_POST['unit_price'], 'pn' => $_POST['part_number'],
            ]);
            $message = 'Part updated.';
        } elseif (isset($_POST['restock'])) {
            $stmt = $pdo->prepare('UPDATE part SET CurrentStock = CurrentStock + :qty WHERE PartNumber = :pn');
            $stmt->execute(['qty' => $_POST['restock_qty'], 'pn' => $_POST['part_number']]);
            $message = 'Stock updated.';
        }
    } catch (PDOException $e) {
        $error = friendlySqlError($e);
    }
}

$belowThresholdOnly = isset($_GET['below_threshold']);
$editPn = $_GET['edit'] ?? '';

$perPage = 10;
$page = currentPage('page');

$whereClause = $belowThresholdOnly ? 'WHERE CurrentStock < ReorderThreshold' : '';

$totalRows = (int)$pdo->query("SELECT COUNT(*) FROM part $whereClause")->fetchColumn();
$totalPages = max(1, (int)ceil($totalRows / $perPage));
$page = min($page, $totalPages);
$offset = ($page - 1) * $perPage;

$parts = $pdo->query(
    "SELECT PartNumber, PartName, Description, CurrentStock, ReorderThreshold, UnitPrice
     FROM part $whereClause
     ORDER BY (CurrentStock < ReorderThreshold) DESC, PartName
     LIMIT $perPage OFFSET $offset"
)->fetchAll();

$editPart = null;
if ($editPn !== '') {
    $s = $pdo->prepare('SELECT * FROM part WHERE PartNumber = :pn');
    $s->execute(['pn' => $editPn]);
    $editPart = $s->fetch();
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Parts Inventory</title>
</head>
<body>
<?php include __DIR__ . '/../../includes/header.php'; ?>

    <a class="back-link" href="workshop_manager_index.php">&larr; Back to dashboard</a>
    <h2>Parts Inventory</h2>

    <?php if ($message !== ''): ?><p class="score-good"><?= htmlspecialchars($message) ?></p><?php endif; ?>
    <?php if ($error !== ''): ?><p class="score-critical"><?= htmlspecialchars($error) ?></p><?php endif; ?>

    <h3><?= $editPart ? 'Edit Part' : 'Add Part' ?></h3>
    <form method="POST">
        <?php if ($editPart): ?>
            <input type="hidden" name="part_number" value="<?= htmlspecialchars($editPart['PartNumber']) ?>">
        <?php endif; ?>
        Name: <input type="text" name="part_name" value="<?= htmlspecialchars($editPart['PartName'] ?? '') ?>" required><br>
        Description: <input type="text" name="description" value="<?= htmlspecialchars($editPart['Description'] ?? '') ?>"><br>
        <?php if (!$editPart): ?>
            Starting Stock: <input type="number" name="current_stock" min="0" value="0" required><br>
        <?php endif; ?>
        Reorder Threshold: <input type="number" name="reorder_threshold" min="1" value="<?= htmlspecialchars($editPart['ReorderThreshold'] ?? '') ?>" required><br>
        Unit Price (VND): <input type="number" name="unit_price" min="1" value="<?= htmlspecialchars($editPart['UnitPrice'] ?? '') ?>" required><br><br>
        <?php if ($editPart): ?>
            <button type="submit" name="update_part" value="1">Save Changes</button>
            <a href="parts.php">Cancel</a>
        <?php else: ?>
            <button type="submit" name="add_part" value="1">Add Part</button>
        <?php endif; ?>
    </form>

    <h3>Inventory</h3>
    <form method="GET">
        <label><input type="checkbox" name="below_threshold" value="1" <?= $belowThresholdOnly ? 'checked' : '' ?> onchange="this.form.submit()"> Below reorder threshold only</label>
    </form>

    <table>
        <tr><th>Part</th><th>Description</th><th>Stock</th><th>Reorder Threshold</th><th>Unit Price</th><th></th></tr>
        <?php foreach ($parts as $p): ?>
            <tr>
                <td><?= htmlspecialchars($p['PartName']) ?></td>
                <td><?= htmlspecialchars($p['Description'] ?? '') ?></td>
                <td class="<?= $p['CurrentStock'] < $p['ReorderThreshold'] ? 'score-critical' : '' ?>"><?= htmlspecialchars($p['CurrentStock']) ?></td>
                <td><?= htmlspecialchars($p['ReorderThreshold']) ?></td>
                <td><?= number_format($p['UnitPrice']) ?> VND</td>
                <td>
                    <a href="?<?= http_build_query(array_merge($_GET, ['edit' => $p['PartNumber']])) ?>">Edit</a>
                    <details style="display:inline;">
                        <summary>Restock</summary>
                        <form method="POST" style="display:inline;">
                            <input type="hidden" name="part_number" value="<?= $p['PartNumber'] ?>">
                            <input type="number" name="restock_qty" min="1" placeholder="Qty" required style="width:70px;">
                            <button type="submit" name="restock" value="1">Add Stock</button>
                        </form>
                    </details>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
    <?= paginationControls($page, $totalPages, 'page') ?>

<?php include __DIR__ . '/../../includes/footer.php'; ?>
</body>
</html>
